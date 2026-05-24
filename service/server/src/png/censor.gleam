import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/int
import gleam/io
import png/png

@external(erlang, "censor", "apply_mask")
pub fn apply_mask(
  target: BitArray,
  mask: BitArray,
  width: Int,
  bit_depth: Int,
  color_type: Int,
) -> BytesTree

pub fn censor_raw(
  photo: png.Photo(BitArray),
  mask: BitArray,
  z_stream: png.ZStream,
) -> Result(png.Photo(BytesTree), String) {
  todo
  // let photo_size = bit_array.byte_size(photo.idat)
  // let mask_size = bit_array.byte_size(mask)

  // case photo_size {
  //   ps if ps > 5120 -> Error("image too large")
  //   ps if ps != mask_size -> {
  //     io.println(
  //       "Wrong size! Photo IDAT: "
  //       <> int.to_string(ps)
  //       <> ", Mask: "
  //       <> int.to_string(mask_size),
  //     )
  //     Error("mask is wrong size")
  //   }
  //   _ if photo.meta.width <= 0 -> Error("invalid width")
  //   _ -> {
  //     let redacted =
  //       apply_mask(
  //         photo.idat,
  //         mask,
  //         photo.meta.width,
  //         photo.meta.bit_depth,
  //         photo.meta.color_type,
  //       )
  //     let compressed = png.compress_stream(z_stream, redacted)
  //     // let compressed = bytes_tree.to_bit_array(compressed)
  //     let idat = png.build_idat(compressed)

  //     Ok(png.Photo(..photo, idat: idat))
  //   }
  // }
}
