import bravo/uset
import gleam/list
import gleam/option.{type Option}
import gleam/result
import pog
import server/sql
import shared/shared_thumbnail
import shared/shared_user.{type Error, NotFound}
import utils
import youid/uuid.{type Uuid}

pub type User {
  User(
    id: Uuid,
    username: String,
    first_name: String,
    last_name: Option(String),
    bio: Option(String),
    available_for_hire: Bool,
    premium: Bool,
    storage_quota: Int,
    storage_quota_used: Int,
  )
}

pub fn get_by_id(db: pog.Connection, id: Uuid) -> Result(User, Error) {
  use user <- utils.db_limit_try(sql.user_find_by_id(db, id), NotFound)
  Ok(user |> from_user_find_by_id)
}

pub fn search(db, username: String, profile_cache) -> List(shared_user.User) {
  {
    use res <- result.try(
      sql.user_search(db, username) |> result.replace_error(Nil),
    )
    use first <- result.try(list.first(res.rows))
    // insert_new fails if already exists so this is safe
    let _ = uset.insert_new(profile_cache, first.username, first.id)
    Ok(list.map(res.rows, fn(row) { shared_user_from_user_search(row) }))
  }
  |> result.unwrap([])
}

// mappers

fn shared_user_from_user_search(user u: sql.UserSearchRow) {
  shared_user.User(
    username: u.username,
    first_name: u.first_name,
    last_name: u.last_name,
    bio: u.bio,
    available_for_hire: u.available_for_hire,
    premium: u.premium,
    photos: [],
  )
}

pub fn from_user_create(user u: sql.UserCreateRow) -> User {
  User(
    id: u.id,
    username: u.username,
    first_name: u.first_name,
    last_name: u.last_name,
    bio: u.bio,
    available_for_hire: u.available_for_hire,
    premium: u.premium,
    storage_quota: u.storage_quota,
    storage_quota_used: u.storage_quota_used,
  )
}

pub fn from_user_find_by_id(user u: sql.UserFindByIdRow) -> User {
  User(
    id: u.id,
    username: u.username,
    first_name: u.first_name,
    last_name: u.last_name,
    bio: u.bio,
    available_for_hire: u.available_for_hire,
    premium: u.premium,
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
  )
}

pub fn from_user_find_by_name(user u: sql.UserFindByNameRow) -> User {
  User(
    id: u.id,
    username: u.username,
    first_name: u.first_name,
    last_name: u.last_name,
    bio: u.bio,
    available_for_hire: u.available_for_hire,
    premium: u.premium,
    storage_quota: u.storage_quota,
    storage_quota_used: u.storage_quota_used,
  )
}

pub fn from_user_update(user u: sql.UserUpdateRow) -> User {
  User(
    id: u.id,
    username: u.username,
    first_name: u.first_name,
    last_name: u.last_name,
    bio: u.bio,
    available_for_hire: u.available_for_hire,
    premium: u.premium,
    storage_quota: u.storage_quota,
    storage_quota_used: u.storage_quota_used,
  )
}
