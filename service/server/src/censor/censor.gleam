import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/result

pub type ZStream

pub type Photo {
  Photo(
    width: Int,
    header_envelope: BitArray,
    raw_pixels: BitArray,
    footer_envelope: BitArray,
  )
}

@external(erlang, "compression.erl", "init_compressor")
pub fn init_compressor() -> ZStream

@external(erlang, "compression.erl", "compress_stream")
fn compress_stream(z: ZStream, data: BytesTree) -> BytesTree

@external(erlang, "compression.erl", "close_compressor")
pub fn close_compressor(z: ZStream) -> Nil

@external(erlang, "censor.erl", "apply_mask")
fn apply_mask(target: BitArray, mask: BitArray, width: Int) -> BytesTree

@external(erlang, "png.erl", "build_idat")
fn build_idat(compressed_data: BitArray) -> BitArray

@external(erlang, "png.erl", "parse_png")
fn parse_png(raw: BitArray) -> #(Int, BitArray, BitArray, BitArray)

pub fn parse_photo(raw: BitArray) -> Photo {
  let #(width, header_envelope, raw_pixels, footer_envelope) = parse_png(raw)
  Photo(width:, header_envelope:, raw_pixels:, footer_envelope:)
}

pub fn censor_png(
  photo: Photo,
  z_stream,
  mask: BitArray,
) -> Result(BitArray, String) {
  // case censor_raw_png(photo.raw_pixels, mask, photo.width, z_stream) {
  //   Ok(censored_pixels) -> {
  //     let idat = build_idat(censored_pixels)
  //     let final_png = <<
  //       photo.header_envelope:bits,
  //       idat:bits,
  //       photo.footer_envelope:bits,
  //     >>
  //     Ok(final_png)
  //   }
  //   Error(e) -> Error(e)
  // }
  censor_raw_png(photo.raw_pixels, mask, photo.width, z_stream)
  |> result.map(build_idat)
  |> result.map(pack_png(photo, _))
}

fn pack_png(photo: Photo, idat: BitArray) -> BitArray {
  <<
    photo.header_envelope:bits,
    idat:bits,
    photo.footer_envelope:bits,
  >>
}

fn censor_raw_png(
  photo: BitArray,
  mask: BitArray,
  width: Int,
  z_stream: ZStream,
) -> Result(BitArray, String) {
  let photo_size = bit_array.byte_size(photo)
  let mask_size = bit_array.byte_size(mask)

  case photo_size {
    ps if ps > 5120 -> Error("image too large")
    ps if ps != mask_size -> Error("mask is wrong size")
    _ if width <= 0 -> Error("invalid width")
    _ -> {
      let redacted = apply_mask(photo, mask, width)
      let compressed = compress_stream(z_stream, redacted)

      Ok(bytes_tree.to_bit_array(compressed))
    }
  }
}
