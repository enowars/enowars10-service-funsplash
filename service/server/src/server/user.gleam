import bravo/uset
import gleam/list
import gleam/option.{type Option}
import gleam/result
import pog
import server/sql
import shared/shared_thumbnail
import shared/shared_user
import youid/uuid

pub type Error {
  Invalid
  NotFound
  LoggedOut
  QueryError(pog.QueryError)
}

pub type User =
  sql.UserFindByNameRow

pub fn from_user_create_row(user u: sql.UserCreateRow) -> User {
  sql.UserFindByNameRow(
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
    storage_quota: u.storage_quota,
    storage_quota_used: u.storage_quota_used,
  )
}

pub fn from_user_find_by_id_row(user u: sql.UserFindByIdRow) -> User {
  sql.UserFindByNameRow(
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
    storage_quota: u.storage_quota,
    storage_quota_used: u.storage_quota_used,
  )
}

pub fn to_shared(
  user: User,
  photos: List(shared_thumbnail.Thumbnail),
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

pub fn get_by_id(db: pog.Connection, id: uuid.Uuid) -> Result(User, Error) {
  use res <- result.try(case sql.user_find_by_id(db, id) {
    Ok(user) -> Ok(user)
    Error(e) -> Error(QueryError(e))
  })
  use user <- result.try(list.first(res.rows) |> result.replace_error(NotFound))

  Ok(user |> from_user_find_by_id_row)
}

pub fn get_by_name(db: pog.Connection, name: String) -> Option(User) {
  sql.user_find_by_name(db, name)
  |> result.map(fn(res) { list.first(res.rows) })
  |> result.unwrap(Error(Nil))
  |> option.from_result
}

pub fn update_cached(
  user_cache uc: uset.USet(uuid.Uuid, User),
  user user: User,
  new_user new_user: fn(User) -> User,
) {
  use cached_user <- result.try(uset.lookup(uc, user.id))
  let user = new_user(cached_user)
  let _ = uset.insert(uc, user.id, user)
}
