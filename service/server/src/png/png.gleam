import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}

pub type ZStream

pub type Bytes =
  Int

pub type Compressed

pub type Uncompressed

pub type Photo(compression_state) {
  Photo(
    width: Int,
    header_envelope: BitArray,
    idat: BitArray,
    footer_envelope: BitArray,
  )
}

pub fn parse_photo(raw: BitArray) -> Photo(Uncompressed) {
  let #(width, header_envelope, idat, footer_envelope) = parse_png(raw)
  Photo(width:, header_envelope:, idat:, footer_envelope:)
}

pub fn size(photo: Photo(Compressed)) -> Bytes {
  bit_array.byte_size(photo.header_envelope)
  + bit_array.byte_size(photo.idat)
  + bit_array.byte_size(photo.footer_envelope)
}

pub fn pack(photo: Photo(Compressed)) -> BitArray {
  <<
    photo.header_envelope:bits,
    photo.idat:bits,
    photo.footer_envelope:bits,
  >>
}

@external(erlang, "png", "build_idat")
pub fn build_idat(compressed_data: BitArray) -> BitArray

@external(erlang, "png", "parse_png")
pub fn parse_png(raw: BitArray) -> #(Int, BitArray, BitArray, BitArray)

@external(erlang, "compression", "init_compressor")
pub fn init_compressor() -> ZStream

@external(erlang, "compression", "compress_stream")
pub fn compress_stream(z: ZStream, data: BytesTree) -> BytesTree

@external(erlang, "compression", "close_compressor")
pub fn close_compressor(z: ZStream) -> Nil

@external(erlang, "compression", "compress")
pub fn compress(data: BytesTree) -> BitArray
