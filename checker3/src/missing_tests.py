from threads import run_in_thread
import httpx
import utils
from dataclasses import asdict
import user
from user import User
import photo
import collection
from photo import Coordinate, Privacy
from logging import LoggerAdapter

from enochecker3 import (
    ChainDB,
    Enochecker,
    PutnoiseCheckerTaskMessage,
    GetnoiseCheckerTaskMessage,
    MumbleException,
)
from connection import Connection
from enochecker3.utils import assert_equals, assert_in

checker = Enochecker("funsplash_missing", 1337)

async def putnoise_update_delete(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)

    # Collection Update Test
    col_name = utils.random_string(10)
    col_id = await collection.create(conn, cookies, name=col_name)
    r = await conn.post(f"/napi/collections/{col_id}", data={"name": col_name + "updated", "description": "desc", "private": "false"}, cookies=cookies, follow_redirects=False)
    assert_equals(r.status_code, 303, "Collection update should redirect")

    # Collection Delete Test
    col_del_id = await collection.create(conn, cookies, name="todelete")
    r = await conn.delete(f"/napi/collections/{col_del_id}", cookies=cookies, follow_redirects=False)
    assert_equals(r.status_code, 303, "Collection delete should redirect")

    # Photo Update Test
    p = photo.Photo(description="test photo update", data=utils.placeholder_png())
    await photo.upload(conn, cookies, p)
    profile = await user.get_profile(conn, u.name, cookies)
    pid = photo.get_by_description_contains(profile, "test photo update").public_id
    r = await conn.post(f"/napi/photos/{pid}", data={"description": "updated desc", "privacy": "public", "show_on_profile": "on"}, cookies=cookies, follow_redirects=False)
    assert_equals(r.status_code, 303, "Photo update should redirect")

    # Photo Delete Test
    p_del = photo.Photo(description="todelete", data=utils.placeholder_png())
    await photo.upload(conn, cookies, p_del)
    profile = await user.get_profile(conn, u.name, cookies)
    pid_del = photo.get_by_description_contains(profile, "todelete").public_id
    r = await conn.delete(f"/napi/photos/{pid_del}", cookies=cookies, follow_redirects=False)
    assert_equals(r.status_code, 303, "Photo delete should redirect")

    await db.set("user", asdict(u))
    await db.set("col_id", col_id)
    await db.set("col_del_id", col_del_id)
    await db.set("pid", pid)
    await db.set("pid_del", pid_del)
    await db.set("col_name", col_name + "updated")


async def getnoise_update_delete(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
        col_id: str = await db.get("col_id")
        col_del_id: str = await db.get("col_del_id")
        pid: str = await db.get("pid")
        pid_del: str = await db.get("pid_del")
        col_name: str = await db.get("col_name")
    except KeyError:
        raise MumbleException("Missing database entry")

    cookies = await user.login(conn, u)

    # Verify Updates
    col_data = await collection.get(conn, col_id, cookies)
    assert_in(col_name, col_data.get("name", ""), "Collection should be updated")

    profile = await user.get_profile(conn, u.name, cookies)
    photo_obj = photo.get_by_description_contains(profile, "updated desc")
    assert_equals(photo_obj.public_id, pid, "Photo description was not updated correctly")

    # Verify Collection Deleted
    r = await conn.get(f"/napi/collections/{col_del_id}", cookies=cookies)
    assert_equals(r.status_code, 404, "Collection should be deleted")

    # Verify Photo Deleted
    r = await conn.get(f"/napi/photos/{pid_del}", cookies=cookies)
    assert_equals(r.status_code, 404, "Photo should be deleted")


async def putnoise_show_on_profile(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)
    hidden_desc = f"hidden photo {utils.random_string(10)}"
    p = photo.Photo(description=hidden_desc, data=utils.placeholder_png(), show_on_profile=False)
    await photo.upload(conn, cookies, p)
    await db.set("user", asdict(u))
    await db.set("hidden_desc", hidden_desc)


async def getnoise_show_on_profile(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
        hidden_desc: str = await db.get("hidden_desc")
    except KeyError:
        raise MumbleException("Missing database entry")

    # Access as anonymous user
    r = await conn.get(f"/napi/users/{u.name}/photos")
    assert_equals(r.status_code, 200, "Should be able to get profile photos")
    photos = r.json()
    for p in photos:
        if hidden_desc in p.get("description", ""):
            raise MumbleException("show_on_profile=False photo is visible to anonymous users")


async def putnoise_login_logout(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)

    r = await conn.get("/napi/logout", cookies=cookies, follow_redirects=False)
    assert_equals(r.status_code, 200, "Logout should succeed with 200 OK")

    # Cookies should be invalidated, creating a collection should fail
    r = await conn.post("/napi/collections", data={"name": "test"}, cookies=cookies, follow_redirects=False)
    if r.status_code not in (401, 403, 404, 303):
        raise MumbleException(f"Logout failed, session still active. Got status: {r.status_code}")
        
    await db.set("user", asdict(u))


async def getnoise_login_logout(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
    except KeyError:
        raise MumbleException("Missing database entry")

    cookies = await user.login(conn, u)
    col_name = utils.random_string(10)
    col_id = await collection.create(conn, cookies, name=col_name)
    assert col_id is not None, "Failed to use new session after login"


async def putnoise_censor_visual(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)
    
    desc = f"censor visual {utils.random_string(10)}"
    p = photo.Photo(description=desc, privacy=Privacy.Premium, data=utils.placeholder_png())
    await photo.upload(conn, cookies, p)
    
    profile = await user.get_profile(conn, u.name, cookies)
    p_obj = photo.get_by_description_contains(profile, desc)
    
    # Store the original image bytes for comparison
    orig_data = await photo.get_data_premium(conn, p_obj.asset_id, cookies)
    
    await db.set("user", asdict(u))
    await db.set("pid", p_obj.public_id)
    await db.set("desc", desc)
    # db.set does not support bytes, so we can convert to hex
    await db.set("orig_data_hex", orig_data.hex())


async def getnoise_censor_visual(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
        pid: str = await db.get("pid")
        desc: str = await db.get("desc")
        orig_data_hex: str = await db.get("orig_data_hex")
    except KeyError:
        raise MumbleException("Missing db entry")
        
    orig_data = bytes.fromhex(orig_data_hex)
    cookies = await user.login(conn, u)

    # Apply a full black mask via websocket
    dim = 1
    black = photo.gen_mask([], Coordinate(dim, dim))
    msgs = await photo.censor(conn, pid, [black])
    
    if not msgs or len(msgs) == 0:
        raise MumbleException("No response from censor endpoint")
        
    # Wait for the background task to upload the newly censored photo
    import asyncio
    await asyncio.sleep(2)
    
    # Retrieve the new photo which is named "original desc (censored)"
    profile = await user.get_profile(conn, u.name, cookies)
    censored_photo_obj = photo.get_by_description_contains(profile, desc + " (censored)")
    
    # Now retrieve the image bytes
    censored_data = await photo.get_data_premium(conn, censored_photo_obj.asset_id, cookies=cookies)
    
    if censored_data == orig_data:
        raise MumbleException("Censoring failed, the retrieved image is identical to the original")


async def putnoise_likes(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)

    p = photo.Photo(description="like me", data=utils.placeholder_png())
    await photo.upload(conn, cookies, p)
    profile = await user.get_profile(conn, u.name, cookies)
    pid = photo.get_by_description_contains(profile, "like me").public_id
    
    p2 = photo.Photo(description="unlike me", data=utils.placeholder_png())
    await photo.upload(conn, cookies, p2)
    profile = await user.get_profile(conn, u.name, cookies)
    pid2 = photo.get_by_description_contains(profile, "unlike me").public_id

    # Like the photos
    r = await conn.post(f"/napi/like/{pid}", cookies=cookies)
    assert_equals(r.status_code, 200, "Like photo should succeed with 200 OK")
    r = await conn.post(f"/napi/like/{pid2}", cookies=cookies)
    assert_equals(r.status_code, 200, "Like photo should succeed with 200 OK")
    
    # Unlike one
    r = await conn.delete(f"/napi/like/{pid2}", cookies=cookies)
    assert_equals(r.status_code, 200, "Unlike photo should succeed with 200 OK")

    await db.set("user", asdict(u))
    await db.set("pid", pid)
    await db.set("pid2", pid2)


async def getnoise_likes(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
        pid: str = await db.get("pid")
        pid2: str = await db.get("pid2")
    except KeyError:
        raise MumbleException("Missing db entry")

    cookies = await user.login(conn, u)
    
    p1_data = await conn.get(f"/napi/photos/{pid}", cookies=cookies)
    assert_equals(p1_data.status_code, 200, "Could not fetch liked photo")
    p1 = photo.Photo.from_dict(p1_data.json())
    assert_equals(p1.user_liked, True, "Liked photo should be in user likes")
    
    p2_data = await conn.get(f"/napi/photos/{pid2}", cookies=cookies)
    assert_equals(p2_data.status_code, 200, "Could not fetch unliked photo")
    p2 = photo.Photo.from_dict(p2_data.json())
    assert_equals(p2.user_liked, False, "Unliked photo is still in user likes")


async def putnoise_collection_photos(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)

    p = photo.Photo(description="collection photo", data=utils.placeholder_png())
    await photo.upload(conn, cookies, p)
    profile = await user.get_profile(conn, u.name, cookies)
    pid = photo.get_by_description_contains(profile, "collection photo").public_id
    
    p2 = photo.Photo(description="collection photo remove", data=utils.placeholder_png())
    await photo.upload(conn, cookies, p2)
    profile = await user.get_profile(conn, u.name, cookies)
    pid2 = photo.get_by_description_contains(profile, "collection photo remove").public_id
    
    col_id = await collection.create(conn, cookies, name="my collection")
    
    # Add photos to collection
    r = await conn.post(f"/napi/collections/{col_id}/photos/{pid}", cookies=cookies)
    assert_equals(r.status_code, 200, "Add photo to collection should succeed")
    r = await conn.post(f"/napi/collections/{col_id}/photos/{pid2}", cookies=cookies)
    assert_equals(r.status_code, 200, "Add photo to collection should succeed")
    
    # Remove one photo
    r = await conn.delete(f"/napi/collections/{col_id}/photos/{pid2}", cookies=cookies)
    assert_equals(r.status_code, 200, "Remove photo from collection should succeed")

    await db.set("user", asdict(u))
    await db.set("col_id", col_id)
    await db.set("pid", pid)
    await db.set("pid2", pid2)


async def getnoise_collection_photos(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
        col_id: str = await db.get("col_id")
        pid: str = await db.get("pid")
        pid2: str = await db.get("pid2")
    except KeyError:
        raise MumbleException("Missing db entry")

    cookies = await user.login(conn, u)

    # Verify the photo is in the collection
    photos_resp = await conn.get(f"/napi/collections/{col_id}/photos", cookies=cookies)
    assert_equals(photos_resp.status_code, 200, "Could not fetch collection photos")
    photos = photos_resp.json()
    photo_ids = [p.get("public_id") for p in photos]
    
    if pid not in photo_ids:
        raise MumbleException("Photo was not successfully added to the collection")
        
    if pid2 in photo_ids:
        raise MumbleException("Photo was not successfully removed from the collection")


async def putnoise_tags_update(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)

    p = photo.Photo(description="tag test photo", data=utils.placeholder_png(), tags=["initial1", "initial2"])
    await photo.upload(conn, cookies, p)
    profile = await user.get_profile(conn, u.name, cookies)
    pid = photo.get_by_description_contains(profile, "tag test photo").public_id

    # Update the tags
    r = await conn.post(
        f"/napi/photos/{pid}",
        data={"description": "tag test photo", "privacy": "public", "show_on_profile": "on", "tags": "updated1,updated2"},
        cookies=cookies,
        follow_redirects=False
    )
    assert_equals(r.status_code, 303, "Photo update (tags) should redirect")
    
    await db.set("user", asdict(u))
    await db.set("pid", pid)


async def getnoise_tags_update(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
        pid: str = await db.get("pid")
    except KeyError:
        raise MumbleException("Missing db entry")

    cookies = await user.login(conn, u)
    
    # Retrieve the photo and verify tags
    p_obj = await photo.get(conn, pid, cookies=cookies)
    
    expected_tags = ["updated1", "updated2"]
    actual_tags = p_obj.tags or []
    
    for tag in expected_tags:
        if tag not in actual_tags:
            raise MumbleException(f"Tag {tag} was not found in updated photo. Tags found: {actual_tags}")


async def putnoise_update_user_and_password(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)

    # 1. Update user profile (username, bio, etc.)
    new_username = u.name + "updated"
    u.name = new_username
    u.bio = "This is a new bio"
    u.first_name = "NewFirst"
    u.last_name = "NewLast"
    
    await user.update(conn, u, cookies=cookies)
    
    # 2. Update password
    new_password = utils.random_string(20)
    r = await conn.post(
        "/napi/account/password",
        data={"password": new_password},
        cookies=cookies,
        follow_redirects=False
    )
    assert_equals(r.status_code, 303, "Password update should redirect")
    
    u.password = new_password
    
    await db.set("user", asdict(u))


async def getnoise_update_user_and_password(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
    except KeyError:
        raise MumbleException("Missing db entry")

    # 1. Verify we can login with the NEW password and NEW username
    cookies = await user.login(conn, u)
    
    # 2. Verify the profile fields updated correctly
    profile = await user.get_profile(conn, u.name, cookies)
    
    assert_equals(profile.get("username"), u.name, "Username was not updated")
    assert_equals(profile.get("bio"), u.bio, "Bio was not updated")
    assert_equals(profile.get("first_name"), u.first_name, "First name was not updated")
    assert_equals(profile.get("last_name"), u.last_name, "Last name was not updated")


async def putnoise_private_photo(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    cookies = await user.register(conn, u)

    p = photo.Photo(description="private test photo", privacy=photo.Privacy.Private, data=utils.placeholder_png())
    await photo.upload(conn, cookies, p)
    profile = await user.get_profile(conn, u.name, cookies)
    photo_obj = photo.get_by_description_contains(profile, "private test photo")
    
    # Assert anonymous fetching returns 303 (redirect to login) or 404 for private photos
    r = await conn.get(f"/images/private_photo-{photo_obj.asset_id}", follow_redirects=False)
    if r.status_code not in [303, 404, 401, 403]:
        raise Exception(f"Private photo should not be accessible anonymously, got status: {r.status_code}")

    await db.set("user", asdict(u))
    await db.set("asset_id", photo_obj.asset_id)


async def getnoise_private_photo(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u: User = User(**await db.get("user"))
        asset_id: str = await db.get("asset_id")
    except KeyError:
        raise MumbleException("Missing db entry")

    cookies = await user.login(conn, u)
    
    # Assert creator can fetch the private photo
    r = await conn.get(f"/images/private_photo-{asset_id}", cookies=cookies, follow_redirects=False)
    assert_equals(r.status_code, 200, "Creator should be able to fetch private photo")
    if not r.content.startswith(b"\x89PNG"):
        raise MumbleException(f"Private photo content mismatch! Expected PNG, got Start: {r.content[:20]}")


async def putnoise_user_search(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u: User = user.random_user()
    await user.register(conn, u)
    
    # We will search for a substring of the username
    search_query = u.name[:5]
    
    await db.set("search_query", search_query)
    await db.set("expected_username", u.name)


async def getnoise_user_search(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        search_query: str = await db.get("search_query")
        expected_username: str = await db.get("expected_username")
    except KeyError:
        raise MumbleException("Missing db entry")

    r = await conn.get(f"/napi/s/users/{search_query}", follow_redirects=False)
    assert_equals(r.status_code, 200, "User search should succeed")
    
    users_list = r.json()
    found = False
    for user_obj in users_list:
        if user_obj.get("username") == expected_username:
            found = True
            break
            
    if not found:
        raise MumbleException(f"User search for {search_query} did not return {expected_username}")


async def putnoise_update_collection(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u = user.random_user()
    cookies = await user.register(conn, u)
    
    col_name = f"col_{utils.random_string(10)}"
    cid = await collection.create(conn, cookies, col_name, description="desc1")
    
    new_col_name = f"col_{utils.random_string(10)}"
    await collection.update(conn, cid, cookies, new_col_name, description="desc2")
    
    await db.set("user", asdict(u))
    await db.set("cid", cid)
    await db.set("expected_name", new_col_name)

async def getnoise_update_collection(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u = User(**await db.get("user"))
        cid = await db.get("cid")
        expected_name = await db.get("expected_name")
    except KeyError:
        raise MumbleException("Missing db entry")
        
    cookies = await user.login(conn, u)
    col_data = await collection.get(conn, cid, cookies)
    
    if col_data.get("name") != expected_name:
        raise MumbleException(f"Expected collection name {expected_name}, got {col_data.get('name')}")


async def putnoise_update_photo(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u = user.random_user()
    cookies = await user.register(conn, u)
    
    p = photo.Photo(description="orig", data=utils.placeholder_png())
    await photo.upload(conn, cookies, p)
    
    profile = await user.get_profile(conn, u.name, cookies)
    p_obj = photo.get_by_description_contains(profile, "orig")
    
    new_desc = f"updated_{utils.random_string(10)}"
    p_obj.description = new_desc
    await photo.update(conn, cookies, p_obj.public_id, p_obj)
    
    await db.set("user", asdict(u))
    await db.set("pid", p_obj.public_id)
    await db.set("expected_desc", new_desc)

async def getnoise_update_photo(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u = User(**await db.get("user"))
        pid = await db.get("pid")
        expected_desc = await db.get("expected_desc")
    except KeyError:
        raise MumbleException("Missing db entry")
        
    cookies = await user.login(conn, u)
    p_obj = await photo.get(conn, pid, cookies)
    
    if p_obj.description != expected_desc:
        raise MumbleException(f"Expected photo description {expected_desc}, got {p_obj.description}")

async def putnoise_update_password(
    task: PutnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    u = user.random_user()
    cookies = await user.register(conn, u)
    
    new_password = utils.random_string(15)
    await user.change_password(conn, new_password, cookies)
    
    u.password = new_password
    await db.set("user", asdict(u))

async def getnoise_update_password(
    task: GetnoiseCheckerTaskMessage,
    db: ChainDB,
    logger: LoggerAdapter,
    conn: Connection,
):
    logger.info(f"Starting {task.method} {task.variant_id}...")
    try:
        u = User(**await db.get("user"))
    except KeyError:
        raise MumbleException("Missing db entry")
        
    # login with new password should succeed
    await user.login(conn, u)

