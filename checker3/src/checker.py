import re
import json
import asyncio
from typing import Optional
from logging import LoggerAdapter
from httpx import AsyncClient

from utils import (
    get_placeholder_png,
    random_string,
    CHARSET_ALPHANUMERIC,
    CHARSET_LETTERS,
    CHARSET_ALPHANUMERIC_MIXED,
    CHARSET_UPPER_ALPHANUMERIC,
    Connection,
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
from enochecker3.utils import assert_equals, assert_in

"""
Checker config
"""

SERVICE_PORT = 1337
checker = Enochecker("funsplash", SERVICE_PORT)
app = lambda: checker.app


"""
Utility functions
"""


@checker.register_dependency
def _get_connection(client: AsyncClient, logger: LoggerAdapter) -> Connection:
    return Connection(client, logger)


"""
CHECKER FUNCTIONS
"""


@checker.putflag(0)
async def putflag_note(
    task: PutflagCheckerTaskMessage,
    db: ChainDB,
    conn: Connection,
    logger: LoggerAdapter,
) -> None:
    username = random_string(12, CHARSET_ALPHANUMERIC)
    first_name = random_string(10, CHARSET_LETTERS)
    password = random_string(16, CHARSET_ALPHANUMERIC_MIXED)

    await conn.register_user(username, password, first_name)
    await conn.login_user(username, password)

    await conn.upload_photo(
        description=task.flag,
        premium=True,
        private=False,
        location="Berlin",
        camera="Gemini",
        tags="flag",
        photo_name="flag.png",
        photo_data=get_placeholder_png(),
    )

    photo_id = None
    for attempt in range(10):
        try:
            profile_html = await conn.get_user_profile(username)
            profile_data = json.loads(profile_html)
            photos = profile_data.get("photos", [])
            if photos:
                photo_id = photos[0].get("public_id") or photos[0].get("asset_id")
                if photo_id:
                    break
        except Exception:
            pass
        await asyncio.sleep(2)

    if not photo_id:
        raise MumbleException("Uploaded photo did not appear on profile")

    logger.debug(f"Got photo_id {photo_id}")
    await db.set("userdata", (username, password, photo_id))
    return username


@checker.getflag(0)
async def getflag_note(
    task: GetflagCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
) -> None:
    try:
        username, password, photo_id = await db.get("userdata")
    except KeyError:
        raise MumbleException("Missing database entry from putflag")

    await conn.login_user(username, password)

    # Check photo metadata
    r = await conn.client.get(f"/photos/{photo_id}", headers=conn._get_headers())
    if r.status_code != 200:
        raise MumbleException(f"Failed to retrieve photo metadata: {r.status_code}")

    if task.flag not in r.text:
        raise MumbleException("Flag not found in photo metadata")

    # Check photo data
    photo_content = await conn.get_photo(photo_id, premium=True)
    if len(photo_content) == 0:
        raise MumbleException("Downloaded photo is empty")


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
    randomNote = random_string(36, CHARSET_UPPER_ALPHANUMERIC)

    await conn.register_user(username, password, first_name)
    await conn.login_user(username, password)

    await conn.upload_photo(
        description=randomNote,
        premium=False,
        private=False,
        location="Munich",
        camera="Gemini",
        tags="noise",
        photo_name="noise.png",
        photo_data=get_placeholder_png(),
    )

    noteId = None
    for attempt in range(10):
        try:
            profile_html = await conn.get_user_profile(username)
            profile_data = json.loads(profile_html)
            photos = profile_data.get("photos", [])
            if photos:
                noteId = photos[0].get("public_id") or photos[0].get("asset_id")
                if noteId:
                    break
        except Exception:
            pass
        await asyncio.sleep(2)

    if not noteId:
        raise MumbleException("Noise photo did not appear on profile")

    await db.set("noise_data", (username, password, noteId, randomNote))


@checker.getnoise(0)
async def getnoise0(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    try:
        username, password, noteId, randomNote = await db.get("noise_data")
    except KeyError:
        raise MumbleException("Missing database entry from putnoise")

    await conn.login_user(username, password)

    r = await conn.client.get(f"/photos/{noteId}", headers=conn._get_headers())
    if r.status_code != 200:
        raise MumbleException(f"Failed to retrieve noise metadata: {r.status_code}")

    if randomNote not in r.text:
        raise MumbleException("Resulting noise was found to be incorrect")


@checker.havoc(0)
async def havoc0(
    task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection
):
    r = await conn.client.get("/")
    assert_equals(r.status_code, 200, "Service root is not reachable")


@checker.havoc(1)
async def havoc1(
    task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection
):
    username = random_string(12)
    password = random_string(12)
    await conn.register_user(username, password, "Dummy")
    profile_json = await conn.get_user_profile(username)
    assert_in(username, profile_json, "Username not found in profile")


@checker.havoc(2)
async def havoc2(
    task: HavocCheckerTaskMessage, logger: LoggerAdapter, conn: Connection
):
    r = await conn.client.get("/photos/00000000-0000-0000-0000-000000000000")
    assert_equals(r.status_code, 404, "Non-existent photo should return 404")


@checker.exploit(0)
async def exploit0(
    task: ExploitCheckerTaskMessage,
    searcher: FlagSearcher,
    conn: Connection,
    logger: LoggerAdapter,
) -> Optional[str]:
    return None


if __name__ == "__main__":
    checker.run()
