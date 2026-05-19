import gleam/bool
import gleam/result

pub fn main() {
  let is_valid = Ok(True)
  use <- bool.guard(when: is_valid != Ok(True), return: Error(Nil))
  Ok(1)
}
