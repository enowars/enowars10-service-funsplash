import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}

pub type ZStream

pub type Bytes =
  Int

pub type Meta {
  Meta(width: Int, height: Int, bit_depth: Int, color_type: Int)
}

pub type Photo(idat_type) {
  Photo(
    meta: Meta,
    header_envelope: BitArray,
    idat: idat_type,
    footer_envelope: BitArray,
  )
}

pub fn parse_photo(raw: BitArray) -> Photo(BitArray) {
  let #(
    #(width, height, bit_depth, color_type),
    header_envelope,
    idat,
    footer_envelope,
  ) = parse_png(raw)
  Photo(
    Meta(width:, height:, bit_depth:, color_type:),
    header_envelope:,
    idat:,
    footer_envelope:,
  )
}

pub fn size(photo: Photo(BytesTree)) -> Bytes {
  bit_array.byte_size(photo.header_envelope)
  + bytes_tree.byte_size(photo.idat)
  + bit_array.byte_size(photo.footer_envelope)
}

pub fn pack(photo: Photo(BytesTree)) -> BitArray {
  bytes_tree.from_bit_array(photo.header_envelope)
  |> bytes_tree.append_tree(photo.idat)
  |> bytes_tree.append(photo.footer_envelope)
  |> smuggle_tree
}

@external(erlang, "erlang", "iolist_to_binary")
fn smuggle_tree(tree: BytesTree) -> BitArray

@external(erlang, "png", "build_idat")
pub fn build_idat(compressed_data: BytesTree) -> BytesTree

@external(erlang, "png", "parse_png")
fn parse_png(
  raw: BitArray,
) -> #(#(Int, Int, Int, Int), BitArray, BitArray, BitArray)

@external(erlang, "compression", "init_compressor")
pub fn init_compressor() -> ZStream

@external(erlang, "compression", "compress_stream")
pub fn compress_stream(z: ZStream, data: BytesTree) -> BytesTree

@external(erlang, "compression", "close_compressor")
pub fn close_compressor(z: ZStream) -> Nil

@external(erlang, "compression", "compress")
pub fn compress(data: BytesTree) -> BytesTree
