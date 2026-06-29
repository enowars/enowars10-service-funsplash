from enochecker3 import MumbleException
from dataclasses import dataclass
from connection import Connection
from enochecker3.utils import assert_equals
import websockets
import asyncio
import qr
import httpx
from typing import NamedTuple, Optional
from enum import StrEnum


class Coordinate(NamedTuple):
    x: int
    y: int


class Privacy(StrEnum):
    Private = "private"
    Premium = "premium"
    Public = "public"


@dataclass
class Photo:
    description: str
    tags: Optional[list[str]] = None
    privacy: Privacy = Privacy.Public
    location: str = "Berlin"
    camera: str = "Sony Beta"
    show_on_profile: bool = True
    public_id: Optional[str] = None
    asset_id: Optional[str] = None
    creator: Optional[str] = None
    data: Optional[bytes] = None
    views: int = 0
    likes: int = 0
    downloads: int = 0

    @classmethod
    def from_dict(cls, data: dict) -> "Photo":
        """Creates a Photo instance from a dictionary (JSON response)."""
        # If it's a full Photo response, it has 'thumbnail'
        if "thumbnail" in data:
            t = data["thumbnail"]
            s = data.get("stats", {})
            return cls(
                public_id=t["public_id"],
                asset_id=t["asset_id"],
                creator=t.get("creator", "unknown"),
                description=t.get("description", ""),
                privacy=Privacy(t.get("privacy", "public")),
                location=data.get("location", ""),
                camera=data.get("camera", ""),
                tags=data.get("tags", []),
                show_on_profile=bool(t.get("show_on_profile", True)),
                data=bytes(data.get("data", [])),
                views=s.get("views", 0),
                likes=s.get("likes", 0),
                downloads=s.get("downloads", 0),
            )
        # Otherwise assume it's a Thumbnail (e.g. from profile)
        return cls(
            public_id=data["public_id"],
            asset_id=data["asset_id"],
            creator=data.get("creator", "unknown"),
            description=data.get("description", ""),
            privacy=Privacy(data.get("privacy", "public")),
            location=data.get("location", ""),
            camera=data.get("camera", ""),
            tags=data.get("tags", []),
            show_on_profile=bool(data.get("show_on_profile", True)),
            data=bytes(data.get("data", [])),
            views=data.get("views", 0),
            likes=data.get("likes", 0),
            downloads=data.get("downloads", 0),
        )


async def get_data_premium(
    conn: Connection, asset_id: str, cookies=None, expected_code: int = 200
):
    r = await conn.get(f"/images/premium_photo-{asset_id}", cookies=cookies, timeout=15)
    assert_equals(r.status_code, expected_code)
    return r.content


async def get_data(
    conn: Connection, asset_id: str, cookies=None, expected_code: int = 200
):
    r = await conn.get(f"/images/photo-{asset_id}", cookies=cookies)
    assert_equals(r.status_code, expected_code)
    return r.content


async def get(
    conn: Connection, public_id: str, cookies=None, expected_code: int = 200
) -> Photo:
    r = await conn.get(f"/napi/photos/{public_id}", cookies=cookies)
    assert_equals(r.status_code, expected_code)
    try:
        return Photo.from_dict(r.json())
    except Exception:
        raise MumbleException("couldnt parse photo metadata")


def get_by_description_contains(
    profile_json, contain: str, not_contain: Optional(str) = None
) -> Photo:
    contain = contain.lower()
    for p in profile_json.get("photos", []):
        description = (p.get("description") or "").lower()
        if contain in description and (
            not_contain is None or not_contain not in description
        ):
            return Photo.from_dict(p)
    raise MumbleException(f"asset_id not found for description containing: {contain}")


async def upload(conn: Connection, cookies, photo: Photo):
    payload = {
        "description": photo.description,
        "location": photo.location,
        "camera": photo.camera,
        "tags": ",".join(photo.tags),
    }

    payload["privacy"] = str(photo.privacy)
    if photo.show_on_profile:
        payload["show_on_profile"] = "true"

    files = {"photo": ("photo_name", photo.data, "image/png")}

    r = await conn.post(
        "/napi/upload",
        data=payload,
        files=files,
        cookies=cookies,
        timeout=httpx.Timeout(30.0, read=None),
    )

    assert_equals(r.status_code, 303)


async def censor(conn: Connection, public_id: str, masks: list[bytearray]) -> list[str]:
    addr = await conn.get_addr()
    responses: list[str] = []
    uri = f"ws://{addr.ip}:{addr.port}/napi/censor/{public_id}"

    async with websockets.connect(uri, close_timeout=30) as ws:

        async def sender():
            for mask in masks:
                await ws.send(mask)

        async def receiver():
            for _ in range(len(masks)):
                try:
                    r = await asyncio.wait_for(ws.recv(), timeout=10)
                    responses.append(r)
                except Exception:
                    break

        # Run sender and receiver concurrently
        await asyncio.gather(sender(), receiver())

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

    for keep in keep_list:
        set_pixel(keep.x, keep.y, a=0)

    return mask


def gen_mask_range(
    keep_start: Coordinate, keep_end: Coordinate, dimensions: Coordinate
) -> bytearray:
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

    def keep(x1, y1, x2, y2):
        for y in range(y1, y2):
            for x in range(x1, x2):
                set_pixel(x, y, a=0)

    keep(keep_start.x, keep_start.y, keep_end.x, keep_end.y)
    return mask


def exploit_masks(size: int = 33) -> list[bytearray]:
    masks = []
    for y in range(size):
        for x in range(size):
            if qr.is_static(x, y, size):
                continue
            masks.append(gen_mask([Coordinate(x, y)], Coordinate(size, size)))
    return masks
