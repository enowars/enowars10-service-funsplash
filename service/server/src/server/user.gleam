import gleam/list
import gleam/option.{type Option}
import gleam/result
import pog
import server/sql
import shared/shared_photo
import shared/shared_user
import youid/uuid

pub type User =
  sql.UserFindByIdRow

pub fn from_user_find_by_name_row(user u: sql.UserFindByNameRow) -> User {
  sql.UserFindByIdRow(
    id: u.id,
    username: u.username,
    first_name: u.first_name,
    last_name: u.last_name,
    bio: u.bio,
    available_for_hire: u.available_for_hire,
    premium: u.premium,
    password: u.password,
    created_at: u.created_at,
    updated_at: u.updated_at,
  )
}

pub fn to_shared(
  user: User,
  photos: List(shared_photo.Photo),
) -> shared_user.User {
  shared_user.User(
    username: user.username,
    first_name: user.first_name,
    last_name: user.last_name,
    bio: user.bio,
    available_for_hire: user.available_for_hire,
    premium: user.premium,
    photos:,
    // TODO: change to most recent 3 for pagination
  )
}

pub fn get_by_id(db: pog.Connection, id: String) -> Option(User) {
  let user = {
    use id <- result.try(id |> uuid.from_string)
    sql.user_find_by_id(db, id)
    |> result.map(fn(res) { list.first(res.rows) })
    |> result.unwrap(Error(Nil))
    |> result.replace_error(Nil)
  }
  user |> option.from_result
}

pub fn get_by_name(db: pog.Connection, name: String) -> Option(User) {
  sql.user_find_by_name(db, name)
  |> result.map(fn(res) { list.first(res.rows) })
  |> result.unwrap(Error(Nil))
  |> result.map(from_user_find_by_name_row)
  |> option.from_result
}
