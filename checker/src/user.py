import random
from dataclasses import dataclass
from connection import Connection
from enochecker3.utils import assert_equals
from enochecker3.utils import MumbleException
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


def random_user(uname_len: int = 5) -> User:
    return User(
        name=random_string(
            random.randrange(uname_len, uname_len + 10), CHARSET_ALPHANUMERIC
        ),
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


async def change_password(
    connection: Connection,
    new_password: str,
    cookies=None,
    expected_code: int = 303,
) -> None:
    r = await connection.post(
        "/napi/account/password",
        data={
            "password": new_password,
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


async def get(
    connection: Connection, username: str, cookies=None, expected_code: int = 200
):
    r = await connection.get(f"/napi/users/{username}", cookies=cookies, timeout=15)
    assert_equals(r.status_code, expected_code)

    try:
        data = r.json()
    except Exception as e:
        raise MumbleException(f"couldn't decode profile: {e}")

    return data


async def get_photos(
    connection: Connection, username: str, cookies=None, expected_code: int = 200
):
    r = await connection.get(
        f"/napi/users/{username}/photos", cookies=cookies, timeout=15
    )
    assert_equals(r.status_code, expected_code)

    try:
        data = r.json()
    except Exception as e:
        raise MumbleException(f"couldn't decode photos: {e}")

    return data


async def get_profile(
    connection: Connection, username: str, cookies=None, expected_code: int = 200
):
    profile = await get(connection, username, cookies, expected_code)
    photos = await get_photos(connection, username, cookies, expected_code)

    profile["photos"] = photos

    return profile


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
