pub fn defer(defer: fn() -> a, first: fn() -> b) -> b {
  let res = first()
  defer()
  res
}
