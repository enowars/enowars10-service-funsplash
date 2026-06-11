import httpx
import utils
import asyncio
from dataclasses import asdict
import user
from user import User
import qr
import photo
import uuid
from photo import Photo, Coordinate
from logging import LoggerAdapter

from utils import (
    random_string,
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
async def _get_connection(
    client: httpx.AsyncClient, logger: LoggerAdapter
) -> Connection:
    max_retries = 30
    for i in range(max_retries):
        try:
            resp = await client.get("/")
            if resp.status_code == 200:
                logger.info(f"Service is reachable after {i} retries.")
                return Connection.wrap(client, logger)
        except (httpx.ConnectError, httpx.ConnectTimeout):
            pass

        if i < max_retries - 1:
            logger.info(f"Waiting for service... ({i + 1}/{max_retries})")
            await asyncio.sleep(2)

    logger.error("Service did not become reachable in time.")
    return Connection.wrap(client, logger)


""""
CHECKER FUNCTIONS
"""


@checker.putflag(0)
async def putflag0(
    task: PutflagCheckerTaskMessage,
    db: ChainDB,
    conn: Connection,
    logger: LoggerAdapter,
) -> None:
    u: User = user.random_user()
    await user.register(conn, u)
    cookies = await user.login(conn, u)
    logger.info(f"{cookies=}")

    p: Photo = Photo(
        description=f"a flag but its premium and you are poor {random_string(16, CHARSET_ALPHANUMERIC_MIXED)}",
        premium=True,
        tags=["flag", "secret", "premium"],
        data=qr.generate_qr_flag(task.flag),
    )
    await photo.upload(conn=conn, cookies=cookies, photo=p)

    profile = await user.get_profile(conn, u.name)
    pid: str = photo.get_by_description_contains(profile, p.description).public_id
    p: Photo = await photo.get(conn, pid)
    data = await photo.get_data_premium(conn, p.asset_id, cookies)

    flag_got = qr.decode(data)
    assert_equals(flag_got, task.flag)

    await db.set("user", asdict(u))
    await db.set("photo", asdict(p))
    return u.name


@checker.getflag(0)
async def getflag0(
    task: GetflagCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
) -> None:
    try:
        u: User = User(**await db.get("user"))
        p: Photo = Photo(**await db.get("photo"))
    except KeyError:
        raise MumbleException("Missing database entry from putflag")

    profile = await user.get_profile(conn, u.name)
    pid: str = photo.get_by_description_contains(profile, p.description).public_id
    p2: Photo = await photo.get(conn, pid)
    assert_equals(
        p, p2, "photo was returned differently from profile how it was stored"
    )

    cookies = await user.login(conn, u)
    p_data = await photo.get_data_premium(conn, p.asset_id, cookies)
    flag_got = qr.decode(p_data)
    assert_equals(flag_got, task.flag)

    p_data = await photo.get_data_premium(conn, p.asset_id)
    try:
        flag_got = qr.decode(p_data)
        assert_equals(flag_got, task.flag)
    except Exception:
        return

    raise MumbleException("could decode flag even when not logged in")


@checker.putnoise(0)
async def upload_image(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    u: User = user.random_user()
    await user.register(conn, u)
    cookies = await user.login(conn, u)

    p: Photo = photo.Photo(
        description=random_string(36, CHARSET_UPPER_ALPHANUMERIC),
        camera="Sony Alpha",
        tags=["idk", "noise"],
        data=utils.placeholder_png(),
    )
    await photo.upload(conn=conn, cookies=cookies, photo=p)

    profile = await user.get_profile(conn, u.name)
    p2: Photo = photo.get_by_description_contains(profile, p.description)
    p2: Photo = await photo.get(conn, p2.public_id)
    p2.data = await photo.get_data(conn, p2.asset_id)

    await db.set("user", asdict(u))
    await db.set("photo", asdict(p2))


@checker.getnoise(0)
async def get_image(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    try:
        u: User = User(**await db.get("user"))
        p: Photo = Photo(**await db.get("photo"))
    except KeyError:
        raise MumbleException("Missing database entry from putnoise")

    profile = await user.get_profile(conn, u.name)
    p2: Photo = photo.get_by_description_contains(profile, p.description)
    p3: Photo = await photo.get(conn, p2.public_id)
    p3.data = await photo.get_data(conn, p.asset_id)
    assert_equals(p, p3)


@checker.putnoise(1)
async def censor_put(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    u: User = user.random_user()
    await user.register(conn, u)
    cookies = await user.login(conn, u)

    fake_flag = f"ONE{random_string(48)}"

    p: Photo = photo.Photo(
        description=random_string(36, CHARSET_UPPER_ALPHANUMERIC),
        premium=True,
        camera="Sony Alpha",
        tags=["idk", "flag"],
        show_on_profile=True,
        data=qr.generate_qr_flag(fake_flag),
    )
    await photo.upload(conn=conn, cookies=cookies, photo=p)
    profile = await user.get_profile(conn, u.name)
    p: Photo = photo.get_by_description_contains(profile, p.description)

    await db.set("fake_flag", fake_flag)
    await db.set("user", asdict(u))
    await db.set("photo", asdict(p))


@checker.getnoise(1)
async def censor_get(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    try:
        ff: str = await db.get("fake_flag")
        u: User = User(**await db.get("user"))
        p: Photo = Photo(**await db.get("photo"))
    except KeyError:
        raise MumbleException("Missing database entry from putnoise")

    dim = 33
    black = photo.gen_mask([], Coordinate(dim, dim))
    half = photo.gen_mask_range(
        Coordinate(0, 0), Coordinate(dim, dim // 2), Coordinate(dim, dim)
    )
    full = photo.gen_mask_range(
        Coordinate(0, 0), Coordinate(dim, dim), Coordinate(dim, dim)
    )

    addr = await conn.get_addr()
    msgs = await photo.censor(addr, p.public_id, [black, half, full])

    def get_size(msg):
        return int(msg.split(":")[1])

    is_sorted = all(
        get_size(msgs[i]) < get_size(msgs[i + 1]) for i in range(len(msgs) - 1)
    )

    # TODO: save image and check if censoring/not censoring worked

    assert_equals(is_sorted, True, "something went wrong with the censoring size")


@checker.havoc(0)
async def index(task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection):
    r = await conn.get("/")
    assert_equals(r.status_code, 200, "Service root is not reachable")


@checker.havoc(1)
async def create_and_get_user(
    task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection
):
    u: User = User(random_string(12), random_string(12), random_string(12))
    await user.register(conn, u)
    profile = await user.get_profile(conn, u.name)

    assert_in(u.name, profile["username"], "Username not found in profile")


@checker.havoc(2)
async def get_non_existant_photo(
    task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection
):
    await photo.get_data(conn, uuid.uuid7(), expected_code=404)


@checker.exploit(0)
async def exploit_censor(
    task: ExploitCheckerTaskMessage,
    searcher: FlagSearcher,
    conn: Connection,
    logger: LoggerAdapter,
) -> str:
    assert task.attack_info is not None

    # u: user = user.random_user()
    # await user.register(conn, u)
    # cookie_header = await user.login(conn, u)

    username = task.attack_info
    profile = await user.get_profile(conn, username)
    p: Photo = photo.get_by_description_contains(
        profile, "a flag but its premium and you are poor"
    )

    addr = await conn.get_addr()
    masks = photo.exploit_masks(33)
    res = await photo.censor(addr, p.public_id, masks)
    img = qr.reconstruct_qr(res, 33)
    return qr.decode(img)


if __name__ == "__main__":
    checker.run()
