import random
from dataclasses import dataclass
from connection import Connection
from enochecker3.utils import assert_equals
from utils import (
    random_string,
    CHARSET_ALPHANUMERIC,
    CHARSET_LETTERS,
    CHARSET_ALPHANUMERIC_MIXED,
)


@dataclass
class User:
    name: str
    first_name: str
    password: str
    last_name: str = ""
    bio: str = ""


def random_user() -> User:
    return User(
        name=random_string(random.randrange(5, 15), CHARSET_ALPHANUMERIC),
        first_name=random_string(random.randrange(3, 10), CHARSET_LETTERS),
        password=random_string(random.randrange(15, 30), CHARSET_ALPHANUMERIC_MIXED),
    )


async def update(
    connection: Connection,
    user: User,
    cookies=None,
    expected_code: int = 303,
) -> None:
    r = await connection.post(
        "/napi/account",
        data={
            "username": user.name,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "bio": user.bio,
        },
        cookies=cookies,
    )
    assert_equals(r.status_code, expected_code)
    return


async def register(
    connection: Connection,
    user: User,
    expected_code: int = 303,
) -> None:
    r = await connection.post(
        "/napi/join",
        data={
            "username": user.name,
            "password": user.password,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "bio": user.bio,
        },
    )
    assert_equals(r.status_code, expected_code)
    return dict(r.cookies)


async def get_profile(
    connection: Connection, username: str, cookies=None, expected_code: int = 200
):
    r = await connection.get(f"/napi/users/{username}", cookies=cookies, timeout=15)
    assert_equals(r.status_code, expected_code)

    r_photos = await connection.get(
        f"/napi/users/{username}/photos", cookies=cookies, timeout=15
    )
    assert_equals(r_photos.status_code, expected_code)

    data = r.json()
    data["photos"] = r_photos.json()
    return data


async def login(connection: Connection, user: User, expected_code: int = 303) -> dict:
    r = await connection.post(
        "/napi/login",
        data={
            "username": user.name,
            "password": user.password,
        },
    )

    assert_equals(r.status_code, expected_code)
    return dict(r.cookies)
