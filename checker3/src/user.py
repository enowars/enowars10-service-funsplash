from dataclasses import dataclass
import Connection
import httpx
from utils import random_string
from enochecker3.utils import assert_equals
from enochecker3 import MumbleException


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
    assert_equals(r.status_code, 302)  # TODO: check if real code


async def get_profile(connection: Connection, username: str, cookie):
    r = await connection.get(f"/@{username}", cookies=cookie)
    assert_equals(r.status_code, 200)
    r.content


async def login(
    connection: Connection, username: str, password: str, first_name: str
) -> str:
    r = await connection.post(
        "/login",
        data={
            "username": username,
            "password": password,
        },
    )

    assert_equals(r.status_code, 302)

    # TODO: check if only one cookie and is valid etc.
    r.cookies["uid"]


async def upload_photo(
    connection: Connection,
    cookie,
    description: str,
    premium: bool,
    private: bool,
    location: str,
    camera: str,
    tags: str,
    photo_name: str,
    photo_data: bytes,
):
    data = {
        "title": photo_name,
        "description": description,
        "show_on_profile": "true",
        "location": location,
        "camera": camera,
        "tags": tags,
        "premium": "true" if premium else "false",
        "private": "true" if private else "false",
    }

    filename = random_string(10) + ".png"
    files = {"photo": (filename, photo_data, "image/png")}

    r = await connection.post(
        "/upload",
        data=data,
        files=files,
        cookies=cookie,
        timeout=httpx.Timeout(30.0, read=None),
        follow_redirects=False,
    )

    assert_equals(r.status_code, 200)
