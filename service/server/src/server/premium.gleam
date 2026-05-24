import gleam/bit_array
import gleam/bool
import png/censor
import png/png
import youid/uuid

pub fn censor_mask(width: Int, height: Int) -> BitArray {
  let x_start = width / 3
  let x_end = width * 2 / 3
  let y_start = height / 3
  let y_end = height * 2 / 3

  build_rows(0, height, width, x_start, x_end, y_start, y_end, <<>>)
}

fn build_rows(
  y: Int,
  height: Int,
  width: Int,
  x_start: Int,
  x_end: Int,
  y_start: Int,
  y_end: Int,
  acc: BitArray,
) -> BitArray {
  case y == height {
    True -> acc
    False -> {
      let is_horizontal = y >= y_start && y <= y_end

      // Prepend the Filter Byte (0) for this row directly to the accumulator
      let row_acc = <<acc:bits, 0:8>>

      // Build the pixels for this row
      let next_acc =
        build_pixels(0, width, x_start, x_end, is_horizontal, row_acc)

      // Recurse to the next row
      build_rows(y + 1, height, width, x_start, x_end, y_start, y_end, next_acc)
    }
  }
}

fn build_pixels(
  x: Int,
  width: Int,
  x_start: Int,
  x_end: Int,
  is_horizontal: Bool,
  acc: BitArray,
) -> BitArray {
  case x == width {
    True -> acc
    False -> {
      let is_vertical = x >= x_start && x <= x_end

      // Fast-append the RGBA bytes to the accumulator
      let next_acc = case is_horizontal || is_vertical {
        True -> <<acc:bits, 0:8, 0:8, 0:8, 255:8>>
        False -> <<acc:bits, 0:8, 0:8, 0:8, 0:8>>
      }

      // Recurse to the next pixel
      build_pixels(x + 1, width, x_start, x_end, is_horizontal, next_acc)
    }
  }
}

pub fn censor(photo: BitArray) -> BitArray {
  let photo = png.parse_photo(photo)
  let mask = censor_mask(photo.meta.width, photo.meta.height)

  png.Photo(
    ..photo,
    idat: censor.apply_mask(
        photo.idat,
        mask,
        photo.meta.width,
        photo.meta.bit_depth,
        photo.meta.color_type,
      )
      |> png.compress
      |> png.build_idat,
  )
  |> png.pack
}
