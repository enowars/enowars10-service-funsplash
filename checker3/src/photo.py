from enochecker3 import MumbleException
from dataclasses import dataclass
from connection import Connection
from enochecker3.utils import assert_equals
import connection
import websockets
import asyncio
from typing import NamedTuple
from logging import LoggerAdapter


class Coordinate(NamedTuple):
    x: int
    y: int


@dataclass
class Photo:
    public_id: str
    asset_id: str
    description: str
    creator: str
    private: bool
    premium: bool
    show_on_profile: bool

    @classmethod
    def from_dict(cls, data: dict) -> "Photo":
        """Creates a Photo instance from a dictionary (JSON response)."""
        return cls(
            public_id=data["public_id"],
            asset_id=data["asset_id"],
            description=data.get("description", ""),
            creator=data.get("creator", "unknown"),
            private=bool(data.get("private", False)),
            premium=bool(data.get("premium", False)),
            show_on_profile=bool(data.get("show_on_profile", True)),
        )


async def get_data_premium(
    conn: Connection, asset_id: str, cookies=None, expected_code: int = 200
):
    r = await conn.get(f"/premium_photo-{asset_id}", cookies=cookies)
    assert_equals(r.status_code, expected_code)
    return r.content


async def get_data(
    conn: Connection, asset_id: str, cookies=None, expected_code: int = 200
):
    r = await conn.get(f"/photo-{asset_id}", cookies=cookies)
    assert_equals(r.status_code, expected_code)
    return r.content


async def get(
    conn: Connection, public_id: str, cookies=None, expected_code: int = 200
) -> Photo:
    r = await conn.get(f"/photos/{public_id}", cookies=cookies)
    assert_equals(r.status_code, expected_code)
    try:
        return Photo.from_dict(r.json())
    except Exception:
        raise MumbleException("couldnt parse photo metadata")


def get_by_description_contains(profile_json, description: str) -> Photo:
    desc = description.lower()
    for p in profile_json.get("photos", []):
        if desc in (p.get("description") or "").lower():
            return Photo.from_dict(p)
    raise MumbleException(
        f"asset_id not found for description containing: {description}"
    )


async def upload(
    conn: Connection,
    cookies,
    description: str,
    premium: bool,
    private: bool,
    location: str,
    camera: str,
    tags: str,
    photo_name: str,
    photo_data: bytes,
):
    payload = {
        "title": photo_name,
        "description": description,
        "show_on_profile": "true",
        "location": location,
        "camera": camera,
        "tags": tags,
        "premium": "true" if premium else "false",
        "private": "true" if private else "false",
    }

    files = {"photo": (photo_name, photo_data, "image/png")}

    r = await conn.post(
        "/upload",
        data=payload,
        files=files,
        cookies=cookies,
        # timeout=httpx.Timeout(30.0, read=None),
    )

    assert_equals(r.status_code, 303)


async def censor(
    addr: connection.Address, public_id: str, masks: list[bytearray]
) -> list[str]:
    responses: list[str] = []
    uri = f"ws://{addr.ip}:{addr.port}/censor/{public_id}"
    async with websockets.connect(uri, close_timeout=10) as ws:
        for mask in masks:
            await ws.send(mask)
            try:
                r = await asyncio.wait_for(ws.recv(), timeout=5.0)
                responses.append(r)
            except Exception:
                break
    return responses


def gen_mask(keep_list: list[Coordinate], dimensions: Coordinate) -> bytearray:
    row_size = dimensions.x * 4 + 1
    total_size = dimensions.y * row_size
    mask = bytearray(total_size)

    def set_pixel(x, y, r=0, g=0, b=0, a=255):
        if x < 0 or x >= dimensions.x or y < 0 or y >= dimensions.y:
            return
        row_start = y * row_size
        pixel_start = row_start + 1 + (x * 4)
        mask[pixel_start] = r
        mask[pixel_start + 1] = g
        mask[pixel_start + 2] = b
        mask[pixel_start + 3] = a

    # Initialize all pixels as censored (alpha = 255)
    for y in range(dimensions.y):
        for x in range(dimensions.x):
            set_pixel(x, y, a=255)

    # def keep(x1, y1, x2, y2):
    #     for y in range(y1, y2):
    #         for x in range(x1, x2):
    #             set_pixel(x, y, a=0)

    for keep in keep_list:
        set_pixel(keep.x, keep.y, a=0)

    return mask


def exploit_masks(size: int = 33) -> list[bytearray]:
    masks = []
    for x in range(size):
        for y in range(size):
            masks.append(gen_mask([Coordinate(x, y)], Coordinate(size, size)))
    return masks
