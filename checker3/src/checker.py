import httpx
import utils
from dataclasses import asdict
import user
from user import User
import qr
import photo
from photo import Photo
from logging import LoggerAdapter

from utils import (
    random_string,
    CHARSET_ALPHANUMERIC,
    CHARSET_LETTERS,
    CHARSET_ALPHANUMERIC_MIXED,
    CHARSET_UPPER_ALPHANUMERIC,
)
from enochecker3 import (
    ChainDB,
    Enochecker,
    ExploitCheckerTaskMessage,
    FlagSearcher,
    GetflagCheckerTaskMessage,
    PutnoiseCheckerTaskMessage,
    GetnoiseCheckerTaskMessage,
    HavocCheckerTaskMessage,
    MumbleException,
    PutflagCheckerTaskMessage,
)
from connection import Connection
from enochecker3.utils import assert_equals, assert_in

"""
Checker config
"""

SERVICE_PORT = 1337
checker = Enochecker("funsplash", SERVICE_PORT)
app = lambda: checker.app


@checker.register_dependency
def _get_connection(client: httpx.AsyncClient, logger: LoggerAdapter) -> Connection:
    return Connection.wrap(client, logger)


""""
CHECKER FUNCTIONS
"""


@checker.putflag(0)
async def putflag(
    task: PutflagCheckerTaskMessage,
    db: ChainDB,
    conn: Connection,
    logger: LoggerAdapter,
) -> None:
    username = random_string(12, CHARSET_ALPHANUMERIC)
    first_name = random_string(10, CHARSET_LETTERS)
    # password = random_string(16, CHARSET_ALPHANUMERIC_MIXED)
    password = "asdf"
    photo_desc = random_string(16, CHARSET_ALPHANUMERIC_MIXED)

    await user.register(conn, username, password, first_name)
    cookies = await user.login(conn, username, password)

    photo_data = qr.generate_qr_flag(task.flag)

    await photo.upload(
        conn=conn,
        cookies=cookies,
        description=f"a flag but its premium and you are poor {photo_desc}",
        premium=True,
        private=False,
        location="Berlin",
        camera="Sony Beta",
        tags="flag,secret,premium",
        photo_name="flag.png",
        photo_data=photo_data,
    )

    profile = await user.get_profile(conn, username)

    p: Photo = photo.get_by_description_contains(profile, photo_desc)

    data = await photo.get_data_premium(conn, p.asset_id, cookies)

    flag_got = qr.decode(data)
    assert_equals(flag_got, task.flag)

    u = user.User(username, password, first_name)

    await db.set("user_data", asdict(u))
    await db.set("photo_data", asdict(p))
    return u.username


@checker.getflag(0)
async def getflag(
    task: GetflagCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
) -> None:
    try:
        ud = await db.get("user_data")
        u: User = User(**ud)
        pd = await db.get("photo_data")
        p: Photo = Photo(**pd)
    except KeyError:
        raise MumbleException("Missing database entry from putflag")

    cookies = await user.login(conn, u.username, u.password)

    profile = await user.get_profile(conn, u.username)

    p2: Photo = photo.get_by_description_contains(profile, p.description)

    assert_equals(
        p, p2, "photo was returned differently from profile how it was stored"
    )

    p2: Photo = await photo.get(conn, p.public_id)
    assert_equals(p, p2, "photo was returned differently from how it was stored")

    pd = await photo.get_data_premium(conn, p.asset_id, cookies)
    flag_got = qr.decode(pd)
    assert_equals(flag_got, task.flag)

    pd = await photo.get_data_premium(conn, p.asset_id)
    try:
        flag_got = qr.decode(pd)
        assert_equals(flag_got, task.flag)
    except Exception:
        return

    raise MumbleException("could decode flag even when not logged in")


@checker.putnoise(0)
async def putnoise0(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    username = random_string(12, CHARSET_UPPER_ALPHANUMERIC)
    first_name = random_string(12, CHARSET_UPPER_ALPHANUMERIC)
    password = random_string(12, CHARSET_UPPER_ALPHANUMERIC)
    description = random_string(36, CHARSET_UPPER_ALPHANUMERIC)

    await user.register(conn, username, password, first_name)
    cookies = await user.login(conn, username, password)

    await photo.upload(
        conn=conn,
        cookies=cookies,
        description=description,
        premium=False,
        private=False,
        location="Berlin",
        camera="Sony Alpha",
        tags="noise",
        photo_name="noise.png",
        photo_data=utils.placeholder_png(),
    )

    profile = await user.get_profile(conn, username)
    p: Photo = photo.get_by_description_contains(profile, description)
    await photo.get(conn, p.public_id)
    await photo.get_data(conn, p.asset_id)

    await db.set("noise_data", (username, password, description))


@checker.getnoise(0)
async def getnoise0(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    try:
        username, password, description = await db.get("noise_data")
    except KeyError:
        raise MumbleException("Missing database entry from putnoise")

    profile = await user.get_profile(conn, username)
    p: Photo = photo.get_by_description_contains(profile, description)
    p: Photo = await photo.get(conn, p.public_id)
    await photo.get_data(conn, p.asset_id)

    if description not in p.description:
        raise MumbleException("Resulting noise was found to be incorrect")


@checker.havoc(0)
async def index(task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection):
    r = await conn.get("/")
    assert_equals(r.status_code, 200, "Service root is not reachable")


@checker.havoc(1)
async def create_and_get_user(
    task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection
):
    username = random_string(12)
    password = random_string(12)
    first_name = random_string(12)
    await user.register(conn, username, password, first_name)
    profile = await user.get_profile(conn, username)

    assert_in(username, profile["username"], "Username not found in profile")


@checker.havoc(2)
async def get_non_existant_photo(
    task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection
):
    # TODO for after python upgrade? uuid.uuid7()
    await photo.get_data(
        conn, "00000000-0000-0000-0000-000000000000", expected_code=404
    )


@checker.exploit(0)
async def exploit0(
    task: ExploitCheckerTaskMessage,
    searcher: FlagSearcher,
    conn: Connection,
    logger: LoggerAdapter,
) -> str:
    assert task.attack_info is not None

    username = task.attack_info

    profile = await user.get_profile(conn, username)

    p: Photo = photo.get_by_description_contains(
        profile, "a flag but its premium and you are poor"
    )
    cookies = await user.login(conn, username, "asdf")
    data = await photo.get_data_premium(conn, p.asset_id, cookies)
    flag = qr.decode(data)

    return flag


if __name__ == "__main__":
    checker.run()
