import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import pog
import server/sql
import wisp

pub type User =
  sql.FindUserByNameRow

pub fn get(request: wisp.Request, user: String) -> a {
  todo
}

pub fn get_user(db: pog.Connection, name: String) -> Option(User) {
  // TODO: use ETP
  let user = {
    use res <- result.try(
      sql.find_user_by_name(db, name) |> result.replace_error(Nil),
    )
    list.first(res.rows)
  }
  option.from_result(user)
}
