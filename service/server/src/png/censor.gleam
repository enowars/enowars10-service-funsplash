import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/result
import png/photo.{type Compressed, type Photo, type Uncompressed, type ZStream}

@external(erlang, "censor.erl", "apply_mask")
fn apply_mask(target: BitArray, mask: BitArray, width: Int) -> BytesTree

pub fn censor_raw(
  photo: Photo(Uncompressed),
  mask: BitArray,
  z_stream: ZStream,
) -> Result(Photo(Compressed), String) {
  let photo_size = bit_array.byte_size(photo.idat)
  let mask_size = bit_array.byte_size(mask)

  case photo_size {
    ps if ps > 5120 -> Error("image too large")
    ps if ps != mask_size -> Error("mask is wrong size")
    _ if photo.width <= 0 -> Error("invalid width")
    _ -> {
      let redacted = apply_mask(photo.idat, mask, photo.width)
      let compressed = photo.compress_stream(z_stream, redacted)
      let compressed = bytes_tree.to_bit_array(compressed)

      Ok(photo.Photo(..photo, idat: compressed))
    }
  }
}
