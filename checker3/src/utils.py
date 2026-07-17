import qr
import random
from connection import Connection
import os
import string
from photo import Privacy, Photo, Coordinate
import photo
import json
import json

# Common charsets for random string generation
CHARSET_ALPHANUMERIC = string.ascii_lowercase + string.digits
CHARSET_LETTERS = string.ascii_letters
CHARSET_ALPHANUMERIC_MIXED = string.ascii_letters + string.digits
CHARSET_UPPER_ALPHANUMERIC = string.ascii_uppercase + string.digits


def random_capitalize(text):
    return "".join(
        char.upper() if random.choice([True, False]) else char.lower() for char in text
    )


def random_string(length: int, charset: str = CHARSET_ALPHANUMERIC) -> str:
    """Generates a random string of a given length from a given charset."""
    return "".join(random.choices(charset, k=length))


def generate_flag() -> str:
    """Generates a random flag for testing purposes."""
    return "ENO" + random_string(32, CHARSET_UPPER_ALPHANUMERIC)


def placeholder_png() -> bytes:
    """Returns a valid 1x1 transparent PNG placeholder with padding."""
    base = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
    return base + random.randbytes(64)


def cookie_to_header(cookies: dict[str, str]) -> str:
    return "; ".join(f"{name}={value}" for name, value in cookies.items())


async def upload_examples(conn: Connection, cookies):
    # padding_size = 2_040_000  # Adjust slightly to leave room for the masks
    # p_padding = Photo(
    #     description="quotafiller", data=utils.placeholder_png() + (b"A" * padding_size)
    # )
    # await photo.upload(conn=conn, cookies=cookies, photo=p_padding)

    for f in sorted(os.scandir("./photos"), key=lambda e: e.name, reverse=True):
        if f.is_file() is not True:
            continue
        with open(f.path, "rb") as file:
            p: Photo = Photo(
                description=random_string(36, CHARSET_UPPER_ALPHANUMERIC),
                privacy=random.choice([Privacy.Private, Privacy.Public]),
                # privacy=Privacy.Public,
                camera="go pro",
                tags=[],
                data=file.read(),
            )
            await photo.upload(conn, cookies, p)

    p: Photo = photo.Photo(
        description=random_string(36, CHARSET_UPPER_ALPHANUMERIC),
        privacy=Privacy.Premium,
        camera="Sony Alpha",
        tags=["idk", "flag"],
        data=qr.generate_fake_flag(),
    )
    await photo.upload(conn=conn, cookies=cookies, photo=p)


async def fill_user(conn: Connection, p: Photo, dim: int = 33):
    black = photo.gen_mask([], Coordinate(dim, dim))
    _half = photo.gen_mask_range(
        Coordinate(0, 0), Coordinate(dim, dim // 2), Coordinate(dim, dim)
    )
    full = photo.gen_mask_range(
        Coordinate(0, 0), Coordinate(dim, dim), Coordinate(dim, dim)
    )

    async def exceed_quota(mask):
        index = 0
        for i in range(40):
            msg = await photo.censor(conn, p.public_id, [mask])
            if json.loads(msg[0]).get("ok") is False:
                break
            index += 1
        return index

    index1 = await exceed_quota(full)
    index2 = await exceed_quota(black)
    print(f"fill index: {index1}, {index2}")


def get_size(msg):
    data = json.loads(msg)
    return data["usage"] - data["limit"]
