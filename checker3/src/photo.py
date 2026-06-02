from enochecker3 import MumbleException
from dataclasses import dataclass
from connection import Connection
from enochecker3.utils import assert_equals
import httpx


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
