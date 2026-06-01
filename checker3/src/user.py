from dataclasses import dataclass
from connection import Connection
from enochecker3.utils import assert_equals


@dataclass
class User:
    username: str
    password: str
    first_name: str


async def register(
    connection: Connection, username: str, password: str, first_name: str
) -> None:
    r = await connection.post(
        "/join",
        data={
            "username": username,
            "password": password,
            "first_name": first_name,
        },
    )
    assert_equals(r.status_code, 200)  # TODO: check if real code


async def get_profile(connection: Connection, username: str, cookie=None):
    r = await connection.get(f"/@{username}", cookies=cookie)
    assert_equals(r.status_code, 200)
    return r.json()


async def login(connection: Connection, username: str, password: str) -> dict:
    r = await connection.post(
        "/login",
        data={
            "username": username,
            "password": password,
        },
    )

    assert_equals(r.status_code, 303)
    return dict(r.cookies)


async def upload_photo(
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
    )

    assert_equals(r.status_code, 303)
