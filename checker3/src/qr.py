import zlib
import io
from PIL import Image
import qrcode
import secrets
import base64
import pyzbar.pyzbar
from enochecker3 import MumbleException


def decode(img) -> str:
    img = Image.open(io.BytesIO(img))
    decoded = pyzbar.decode(img)
    if not decoded:
        raise MumbleException("couldnt decode flag")
    return decoded[0].data.decode("utf-8")


def create_mask(mode: str) -> bytearray:
    width = 29
    height = 29
    # Each row: 1 dummy filter byte + width * 4 bytes (RGBA)
    row_data_size = width * 4
    row_size = 1 + row_data_size
    total_bytes = height * row_size

    mask = bytearray(total_bytes)

    def set_pixel(x, y, r=0, g=0, b=0, a=255):
        if x < 0 or x >= width or y < 0 or y >= height:
            return
        row_start = y * row_size
        pixel_start = row_start + 1 + (x * 4)
        mask[pixel_start] = r
        mask[pixel_start + 1] = g
        mask[pixel_start + 2] = b
        mask[pixel_start + 3] = a

    # Initialize all pixels as censored (alpha = 255)
    for y in range(height):
        for x in range(width):
            set_pixel(x, y, a=255)

    def keep(x1, y1, x2, y2):
        for y in range(y1, y2):
            for x in range(x1, x2):
                set_pixel(x, y, a=0)

    if mode == "middle":
        # Keep only the center pixel
        mid_x, mid_y = width // 2, height // 2
        set_pixel(mid_x, mid_y, a=0)
        return mask
    elif mode == "middle_up":
        # Keep only the pixel one step up from the center
        mid_x, mid_y = width // 2, height // 2
        set_pixel(mid_x, mid_y - 3, a=0)
        return mask

    if mode == "blackout":
        # Do not keep anything, results in an all-black image
        return mask

    # Always keep structural QR elements for other modes
    keep(0, 0, 7, 7)  # Top-Left
    keep(22, 0, 29, 7)  # Top-Right
    keep(0, 22, 7, 29)  # Bottom-Left
    keep(20, 20, 25, 25)  # Alignment
    keep(8, 6, 21, 7)  # Horizontal Timing
    keep(6, 8, 7, 21)  # Vertical Timing

    # Apply the dynamic data masking rules
    if mode == "nothing":
        keep(0, 0, width, height)
    elif mode == "half":
        keep(0, 0, width, height // 2)
    elif mode == "all":
        pass

    return mask


def generate_qr_flag(flag: str):
    # 1. Generate 36 random bytes, which encodes to exactly 48 Base64 characters
    random_bytes = secrets.token_bytes(36)
    b64_string = base64.b64encode(random_bytes).decode("utf-8")

    # 2. Add your static prefix
    flag = f"ENO{b64_string}"
    print(f"Generated Flag: {flag}")

    # 3. Configure the QR code for the CTF specs
    # Version 3 = 29x29 modules.
    # Level L allows up to 55 bytes (our flag is 51 bytes).
    qr = qrcode.QRCode(
        version=3,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=1,  # 1 module = exactly 1 pixel
        border=0,  # Remove the standard 4-module quiet zone to keep it 29x29
    )

    qr.add_data(flag)

    # fit=False forces it to stay at Version 3 even if it could fit in a smaller one
    qr.make(fit=False)

    # 4. Generate the raw black and white image
    return qr.make_image(fill_color="black", back_color="white")


def simulate_and_save(base_img, pixel_data, test_name, output_filename) -> Image:
    # 1. Calculate the raw zlib oracle size (What the attacker sees)
    raw_bytes = bytes(pixel_data)
    compressed_data = zlib.compress(raw_bytes, level=1)
    oracle_size = len(compressed_data)

    # 2. Save the visual image to disk (What you see to verify your code)
    # Create a new blank 1-bit image with the same dimensions
    out_img = Image.new("1", base_img.size)
    # Put our modified pixels into the image
    out_img.putdata(pixel_data)

    return out_img

    # print(f"[{test_name}]")
    # print(f"  -> Oracle Size: {oracle_size} bytes")
    # print(f"  -> Saved Image: {output_filename}\n")
