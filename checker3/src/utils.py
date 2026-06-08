import random
import string

# Common charsets for random string generation
CHARSET_ALPHANUMERIC = string.ascii_lowercase + string.digits
CHARSET_LETTERS = string.ascii_letters
CHARSET_ALPHANUMERIC_MIXED = string.ascii_letters + string.digits
CHARSET_UPPER_ALPHANUMERIC = string.ascii_uppercase + string.digits


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
