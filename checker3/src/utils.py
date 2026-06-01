import random
from dataclasses import dataclass
import string
import httpx
from logging import LoggerAdapter
from httpx import AsyncClient
from enochecker3 import MumbleException

# Common charsets for random string generation
CHARSET_ALPHANUMERIC = string.ascii_lowercase + string.digits
CHARSET_LETTERS = string.ascii_letters
CHARSET_ALPHANUMERIC_MIXED = string.ascii_letters + string.digits
CHARSET_UPPER_ALPHANUMERIC = string.ascii_uppercase + string.digits


@dataclass
class Photo:
    public_id: str
    asset_id: str
    description: str
    creator: str
    private: bool
    premium: bool
    show_on_profile: bool

    @classmethod
    def from_dict(cls, data: dict) -> "Photo":
        """Creates a Photo instance from a dictionary (JSON response)."""
        return cls(
            public_id=data["public_id"],
            asset_id=data["asset_id"],
            description=data.get("description", ""),
            creator=data.get("creator", "unknown"),
            private=bool(data.get("private", False)),
            premium=bool(data.get("premium", False)),
            show_on_profile=bool(data.get("show_on_profile", True)),
        )


def get_photo_by_description_contains(data, description) -> Photo:
    desc = description.lower()
    for p in data.get("photos", []):
        if desc in (p.get("description") or "").lower():
            return Photo.from_dict(p)
    raise MumbleException(
        f"asset_id not found for description containing: {description}"
    )


def get_placeholder_png() -> bytes:
    """Returns a valid 1x1 transparent PNG placeholder with padding."""
    base = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
    return base + random.randbytes(64)


def random_string(length: int, charset: str = CHARSET_ALPHANUMERIC) -> str:
    """Generates a random string of a given length from a given charset."""
    return "".join(random.choices(charset, k=length))


def generate_flag() -> str:
    """Generates a random flag for testing purposes."""
    return "ENO" + random_string(32, CHARSET_UPPER_ALPHANUMERIC)


class OldConnection:
    def __init__(self, client: AsyncClient, logger: LoggerAdapter):
        self.client = client
        self.logger = logger
        self.uid = None
        self.client.headers.update(
            {
                "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            }
        )

    def _update_cookies(self, response: httpx.Response):
        # Manually track the uid cookie because it's marked Secure
        # and we are on HTTP, so httpx might ignore it.
        if "uid" in response.cookies:
            self.uid = response.cookies["uid"]
            self.logger.debug(f"Manually tracked uid cookie: {self.uid}")

    def _get_headers(self):
        headers = {}
        if self.uid:
            headers["Cookie"] = f"uid={self.uid}"
        return headers

    async def register_user(self, username: str, password: str, first_name: str):
        self.logger.debug(f"Registering user: {username}")
        r = await self.client.post(
            "/join",
            data={
                "username": username,
                "password": password,
                "first_name": first_name,
                "last_name": "Checker",
            },
            follow_redirects=False,
        )
        self._update_cookies(r)
        if r.status_code not in [200, 302, 303]:
            raise MumbleException(f"Failed to register user: {r.status_code}")

    async def login_user(self, username: str, password: str):
        self.logger.debug(f"Logging in user: {username}")
        r = await self.client.post(
            "/login",
            data={
                "username": username,
                "password": password,
            },
            follow_redirects=False,
        )
        self._update_cookies(r)

        # Verify success: check our manually tracked uid or status
        if r.status_code not in [200, 302, 303]:
            raise MumbleException(f"Failed to log in: {r.status_code}")

        if not self.uid:
            # Fallback check if it was already set
            if "uid" in self.client.cookies:
                self.uid = self.client.cookies["uid"]

        if not self.uid:
            raise MumbleException("Failed to obtain session cookie 'uid' after login")

    async def upload_photo(
        self,
        description: str,
        premium: bool,
        private: bool,
        location: str,
        camera: str,
        tags: str,
        photo_name: str,
        photo_data: bytes,
    ):
        self.logger.debug(f"Uploading photo: {photo_name}")

        data = {
            "title": photo_name,
            "description": description,
            "show_on_profile": "true",
            "location": location,
            "camera": camera,
            "tags": tags,
            "premium": "true" if premium else "false",
            "private": "true" if private else "false",
        }

        filename = random_string(10) + ".png"
        files = {"photo": (filename, photo_data, "image/png")}

        try:
            r = await self.client.post(
                "/upload",
                data=data,
                files=files,
                headers=self._get_headers(),  # Force the cookie
                timeout=httpx.Timeout(30.0, read=None),
                follow_redirects=False,
            )
            self._update_cookies(r)
            loc = r.headers.get("Location", "")
            if "User needs to be logged in" in loc:
                raise MumbleException(
                    "Upload failed: Session rejected by service (secure cookie over HTTP?)"
                )
        except Exception:
            raise MumbleException("couldnt upload photo")

    async def get_user_profile(self, username: str) -> str:
        r = await self.client.get(f"/@{username}", headers=self._get_headers())
        if r.status_code != 200:
            raise MumbleException(f"Failed to get user profile: {r.status_code}")
        return r.text

    async def get_photo(self, photo_id: str, premium: bool = False) -> bytes:
        urls = [
            f"/photos/{photo_id}",
            f"/photo-{photo_id}",
            f"/premium_photo-{photo_id}",
        ]

        for url in urls:
            try:
                r = await self.client.get(url, headers=self._get_headers())
                if r.status_code == 200:
                    return r.content
            except Exception:
                continue

        raise MumbleException(f"Failed to get photo {photo_id}")
