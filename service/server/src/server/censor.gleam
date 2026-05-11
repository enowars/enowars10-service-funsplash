@external(erlang, "censor_engine", "apply_mask_and_filter")
fn apply_mask_and_filter(target: BitArray, mask: BitArray) -> BitArray

@external(erlang, "censor_engine", "compress")
fn compress(data: BitArray) -> BitArray

@external(erlang, "censor_engine", "crc32")
fn crc32(data: BitArray) -> Int

pub fn censor_png(image: BitArray, mask: BitArray) -> BitArray {
  todo
}
