import httpx
import asyncio
from typing import Optional
from dataclasses import asdict
import user
import qr
import photo
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


FLAG_REGEX_ASCII = r"ENO[A-Za-z0-9+\/=]{48}"
FLAG_REGEX_UTF8 = r"🥺[A-Za-z0-9+\/=]{48}🥺🥺"
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
    password = random_string(16, CHARSET_ALPHANUMERIC_MIXED)
    photo_desc = random_string(16, CHARSET_ALPHANUMERIC_MIXED)

    await user.register(conn, username, password, first_name)
    cookies = await user.login(conn, username, password)

    photo_data = qr.generate_qr_flag(task.flag)

    await photo.upload_photo(
        conn,
        cookies,
        description=f"a flag but its premium and you are poor 🪙🤑 {photo_desc}",
        premium=True,
        private=False,
        location="Berlin",
        camera="Sony Beta",
        tags="flag,secret,premium",
        photo_name="flag.png",
        photo_data=photo_data,
    )

    profile = await user.get_profile(conn, username)

    p = photo.get_by_description_contains(profile, photo_desc)

    r = await conn.get(f"/premium_photo-{p.asset_id}", cookies=cookies)
    assert_equals(r.status_code, 200)
    flag_got = qr.decode(r.content, logger)
    assert_equals(flag_got, task.flag)

    u = user.User(username, password, first_name)

    await db.set("user_data", asdict(u))
    await db.set("photo_data", asdict(p))
    return u.username


@checker.getflag(0)
async def getflag_note(
    task: GetflagCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
) -> None:
    try:
        u: user.User = user.User(**(await db.get("user_data")))
        p: photo.Photo = photo.Photo(**(await db.get("photo_data")))
    except KeyError:
        raise MumbleException("Missing database entry from putflag")

    cookies = await user.login(conn, u.username, u.password)

    profile = await user.get_profile(conn, u.username)

    logger.info(f"{profile=}")

    p2: photo.Photo = photo.get_by_description_contains(profile, p.description)

    assert_equals(
        p, p2, "photo was returned differently from profile how it was stored"
    )

    # Check photo metadata
    r = await conn.get(f"/photos/{p.public_id}")
    if r.status_code != 200:
        raise MumbleException(f"Failed to retrieve photo metadata: {r.status_code}")
    p2: photo.Photo = photo.Photo.from_dict(r.json())

    assert_equals(p, p2, "photo was returned differently from how it was stored")

    r = await conn.get(f"/premium_photo-{p.asset_id}", cookies=cookies)
    assert_equals(r.status_code, 200)
    flag_got = qr.decode(r.content, logger)
    assert_equals(flag_got, task.flag)

    r = await conn.get(f"/premium_photo-{p.asset_id}")
    assert_equals(r.status_code, 200)
    try:
        flag_got = qr.decode(r.content, logger)
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

    await photo.upload_photo(
        conn=conn,
        cookies=cookies,
        description=description,
        premium=False,
        private=False,
        location="Berlin",
        camera="Sony Alpha",
        tags="noise",
        photo_name="noise.png",
        photo_data=photo.get_placeholder_png(),
    )

    public_id = None
    for attempt in range(10):
        try:
            profile = await user.get_profile(conn, username)
            photos = profile.get("photos", [])
            if photos:
                public_id = photos[0].get("public_id")
                if public_id:
                    break
        except Exception:
            pass
        await asyncio.sleep(2)

    if not public_id:
        raise MumbleException("Noise photo did not appear on profile")

    await db.set("noise_data", (username, password, public_id, description))


@checker.getnoise(0)
async def getnoise0(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    try:
        username, password, public_id, description = await db.get("noise_data")
    except KeyError:
        raise MumbleException("Missing database entry from putnoise")

    # cookies = await user.login(username, password)

    r = await conn.get(f"/photos/{public_id}")
    if r.status_code != 200:
        raise MumbleException(f"Failed to retrieve noise metadata: {r.status_code}")

    if description not in r.text:
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
    profile_json = await user.get_profile(conn, username)
    assert_in(username, profile_json, "Username not found in profile")


@checker.havoc(2)
async def get_non_existant_photo(
    task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection
):
    r = await conn.get("/photos/00000000-0000-0000-0000-000000000000")
    # TODO for after python upgrade?
    # r = await conn.get(f"/photos/{uuid.uuid7()}")
    assert_equals(r.status_code, 404, "Non-existent photo should return 404")


@checker.exploit(0)
async def exploit0(
    task: ExploitCheckerTaskMessage,
    searcher: FlagSearcher,
    conn: Connection,
    logger: LoggerAdapter,
) -> Optional[str]:
    return task.flag


if __name__ == "__main__":
    checker.run()
