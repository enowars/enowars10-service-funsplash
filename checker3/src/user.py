from dataclasses import dataclass
from connection import Connection
from enochecker3.utils import assert_equals


@dataclass
class User:
    username: str
    password: str
    first_name: str


async def register(
    connection: Connection,
    username: str,
    password: str,
    first_name: str,
    expected_code: int = 200,
) -> None:
    r = await connection.post(
        "/join",
        data={
            "username": username,
            "password": password,
            "first_name": first_name,
        },
    )
    assert_equals(r.status_code, expected_code)


async def get_profile(
    connection: Connection, username: str, cookie=None, expected_code: int = 200
):
    r = await connection.get(f"/@{username}", cookies=cookie)
    assert_equals(r.status_code, expected_code)
    return r.json()


async def login(
    connection: Connection, username: str, password: str, expected_code: int = 303
) -> dict:
    r = await connection.post(
        "/login",
        data={
            "username": username,
            "password": password,
        },
    )

    assert_equals(r.status_code, expected_code)
    return dict(r.cookies)
