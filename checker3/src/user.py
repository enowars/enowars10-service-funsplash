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


def random_user() -> User:
    return User(
        name=random_string(random.randrange(5, 15), CHARSET_ALPHANUMERIC),
        first_name=random_string(random.randrange(3, 10), CHARSET_LETTERS),
        password=random_string(random.randrange(15, 30), CHARSET_ALPHANUMERIC_MIXED),
    )


async def register(
    connection: Connection,
    user: User,
    expected_code: int = 200,
) -> None:
    r = await connection.post(
        "/napi/join",
        data={
            "username": user.name,
            "password": user.password,
            "first_name": user.first_name,
        },
    )
    assert_equals(r.status_code, expected_code)


async def get_profile(
    connection: Connection, username: str, cookie=None, expected_code: int = 200
):
    r = await connection.get(f"/napi/users/{username}", cookies=cookie)
    assert_equals(r.status_code, expected_code)
    return r.json()


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
