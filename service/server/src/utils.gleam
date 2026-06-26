import gleam/list
import gleam/result
import pog

pub fn defer(defer: fn() -> a, first: fn() -> b) -> b {
  let res = first()
  defer()
  res
}

pub fn db_limit(
  res: pog.Returned(a),
  err: e,
  next: fn(a) -> Result(b, e),
) -> Result(b, e) {
  case list.first(res.rows) |> result.replace_error(err) {
    Ok(ok) -> next(ok)
    Error(e) -> Error(e)
  }
}

pub fn result_guard(
  when requirement: Result(a, b),
  return consequence: c,
  otherwise alternative: fn(a) -> c,
) -> c {
  case requirement {
    Error(_) -> consequence
    Ok(ok) -> alternative(ok)
  }
}
