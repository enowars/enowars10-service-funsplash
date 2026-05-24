import gleam/io
import png/png
import simplifile

pub fn main() {
  let assert Ok(raw) = simplifile.read_bits("test.png")
  let photo = png.parse_photo(raw)
  io.debug(photo.width)
}
