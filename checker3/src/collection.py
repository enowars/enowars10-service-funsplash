from connection import Connection
from enochecker3.utils import assert_equals
from enochecker3 import MumbleException


async def create(
    conn: Connection,
    cookies,
    name: str,
    description: str = "",
    private: bool = True,
    photo_public_id: str | None = None,
) -> str:
    data = {
        "name": name,
        "description": description,
        "private": "true" if private else "false",
    }
    if photo_public_id is not None:
        data["photo_public_id"] = photo_public_id

    r = await conn.post(
        "/napi/collections",
        data=data,
        cookies=cookies,
        follow_redirects=False,
    )
    assert_equals(r.status_code, 303, "expected redirect after collection creation")

    location = r.headers.get("location", "")
    public_id = location.rsplit("/", 1)[-1]
    assert public_id, f"could not extract public_id from redirect: {location}"
    return public_id


async def get(conn: Connection, public_id: str, cookies=None) -> dict:
    r = await conn.get(f"/napi/collections/{public_id}", cookies=cookies)
    assert_equals(r.status_code, 200)
    try:
        return r.json()
    except Exception as e:
        raise MumbleException(f"cant decode json {e}")


async def update(
    conn: Connection,
    public_id: str,
    cookies,
    name: str,
    description: str = "",
    private: bool = True,
) -> None:
    data = {
        "name": name,
        "description": description,
        "private": "true" if private else "false",
    }
    r = await conn.post(
        f"/napi/collections/{public_id}",
        data=data,
        cookies=cookies,
        follow_redirects=False,
    )
    assert_equals(r.status_code, 303, "expected redirect after collection update")
    return
