import zlib
import io
from PIL import Image
import qrcode
from enochecker3 import MumbleException
import pyzbar.pyzbar


def generate_qr_flag(flag: str) -> bytes:
    qr = qrcode.QRCode(
        version=4,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=1,  # 1 module = exactly 1 pixel
        border=0,  # Remove the standard 4-module quiet zone to keep it 29x29
    )

    qr.add_data(flag)

    # fit=False forces it to stay at Version 3 even if it could fit in a smaller one
    qr.make(fit=False)

    img = qr.make_image(fill_color="black", back_color="white")

    # 5. Convert to PNG bytes for upload
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def decode(img) -> str:
    try:
        # Load the 1px-per-module image
        img_obj = Image.open(io.BytesIO(img)).convert("L")

        # 29x29 pixels is too small for pyzbar's detection engine.
        # We upscale 10x using NEAREST neighbor to preserve the sharp edges.
        # This makes the image 290x290, where each module is 10x10 pixels.
        w, h = img_obj.size
        upscaled = img_obj.resize((w * 10, h * 10), resample=Image.NEAREST)

        # Add a 4-module (40px) white border (Quiet Zone).
        # Without this, pyzbar cannot distinguish the QR markers from the image edge.
        border = 40
        padded = Image.new(
            "L", (upscaled.width + 2 * border, upscaled.height + 2 * border), 255
        )
        padded.paste(upscaled, (border, border))

        decoded = pyzbar.pyzbar.decode(padded)
        if not decoded:
            raise ValueError("No QR code detected after processing")

        return decoded[0].data.decode("utf-8")
    except Exception as e:
        raise MumbleException(f"couldnt decode flag from image: {e}")


def is_static(x: int, y: int, size: int) -> bool:
    # Position Detection Patterns (7x7 squares at corners)
    for ox, oy in [(0, 0), (size - 7, 0), (0, size - 7)]:
        if 0 <= x - ox < 7 and 0 <= y - oy < 7:
            return True

    # Separators around Position Detection Patterns (always white)
    # Top-Left
    if (x == 7 and 0 <= y <= 7) or (y == 7 and 0 <= x <= 7):
        return True
    # Top-Right
    if (x == size - 8 and 0 <= y <= 7) or (y == 7 and size - 8 <= x < size):
        return True
    # Bottom-Left
    if (x == 7 and size - 8 <= y < size) or (y == size - 8 and 0 <= x <= 7):
        return True

    # Alignment Pattern(s) (5x5)
    if size == 33:  # Version 4
        if 24 <= x < 29 and 24 <= y < 29:
            return True
    elif size == 29:  # Version 3
        if 20 <= x < 25 and 20 <= y < 25:
            return True

    # Timing Patterns (Row 6 and Column 6 between position patterns)
    if y == 6 or x == 6:
        return True

    return False


def get_static_pixel(x: int, y: int, size: int) -> int:
    # Position Detection Patterns
    for ox, oy in [(0, 0), (size - 7, 0), (0, size - 7)]:
        if 0 <= x - ox < 7 and 0 <= y - oy < 7:
            dx, dy = x - ox, y - oy
            if dx == 0 or dx == 6 or dy == 0 or dy == 6:
                return 0  # Black outer frame
            if dx == 1 or dx == 5 or dy == 1 or dy == 5:
                return 255  # White inner frame
            return 0  # Black center (3x3)

    # Alignment Patterns
    if size == 33:
        ox, oy = 24, 24
    elif size == 29:
        ox, oy = 20, 20
    else:
        return 255
    if 0 <= x - ox < 5 and 0 <= y - oy < 5:
        dx, dy = x - ox, y - oy
        if dx == 0 or dx == 4 or dy == 0 or dy == 4:
            return 0  # Black outer frame
        if dx == 1 or dx == 3 or dy == 1 or dy == 3:
            return 255  # White inner frame
        return 0  # Black center (1x1)

    # Timing Patterns (alternating black/white)
    if y == 6 or x == 6:
        return 0 if (x + y) % 2 == 0 else 255

    # Separators (Always White)
    return 255


def reconstruct_qr(results: list[str], base_size: int, dim: int = 33):
    pixels = [255] * (dim * dim)
    res_idx = 0
    for y in range(dim):
        for x in range(dim):
            if is_static(x, y, dim):
                pixels[y * dim + x] = get_static_pixel(x, y, dim)
            else:
                if res_idx < len(results):
                    # Oracle: "ok.size:69" means black (0), otherwise white (255)
                    pixels[y * dim + x] = (
                        0
                        if results[res_idx] == f"quota_exceeded_by:{base_size}"
                        else 255
                    )
                    res_idx += 1

    # Create the image
    img = Image.new("L", (dim, dim))
    img.putdata(pixels)

    # Convert to bytes
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


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


def simulate_and_save(base_img, pixel_data, test_name, output_filename) -> Image:
    # 1. Calculate the raw zlib oracle size (What the attacker sees)
    raw_bytes = bytes(pixel_data)
    compressed_data = zlib.compress(raw_bytes, level=1)
    _ = len(compressed_data)

    # 2. Save the visual image to disk (What you see to verify your code)
    # Create a new blank 1-bit image with the same dimensions
    out_img = Image.new("1", base_img.size)
    # Put our modified pixels into the image
    out_img.putdata(pixel_data)

    return out_img

    # print(f"[{test_name}]")
    # print(f"  -> Oracle Size: {oracle_size} bytes")
    # print(f"  -> Saved Image: {output_filename}\n")
