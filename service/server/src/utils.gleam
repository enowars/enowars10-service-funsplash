import gleam/list
import gleam/result
import pog

pub fn defer(defer: fn() -> a, first: fn() -> b) -> b {
  let res = first()
  defer()
  res
}

pub fn db_limit(
  res: Result(pog.Returned(a), pog.QueryError),
) -> Result(a, pog.QueryError) {
  case res {
    Ok(ok) -> {
      case
        ok.rows
        |> list.first
        |> result.replace_error(pog.PostgresqlError(
          "P0002",
          "no_data_found",
          "no_data_found",
        ))
      {
        Ok(row) -> Ok(row)
        Error(err) -> Error(err)
      }
    }
    Error(err) -> Error(err)
  }
}

pub fn db_limit_try(
  res: Result(pog.Returned(a), pe),
  err: e,
  next: fn(a) -> Result(b, e),
) -> Result(b, e) {
  case res {
    Ok(ok) ->
      case ok.rows |> list.first |> result.replace_error(err) {
        Ok(ok) -> next(ok)
        Error(e) -> Error(e)
      }
    Error(_) -> Error(err)
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
