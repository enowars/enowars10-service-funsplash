import bravo/uset
import gleam/option.{type Option}
import gleam/result
import gleam/time/timestamp.{type Timestamp}
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
    created_at: Timestamp,
    updated_at: Timestamp,
    storage_quota: Int,
    storage_quota_used: Int,
  )
}

// TODO: remove password from struct
// add 3 photos to struct

pub fn get_by_id(db: pog.Connection, id: Uuid) -> Result(User, Error) {
  use user <- utils.db_limit(sql.user_find_by_id(db, id), NotFound)
  Ok(user |> from_user_find_by_id)
}

pub fn update_cached(
  user_cache uc: uset.USet(Uuid, User),
  user user: User,
  new_user new_user: fn(User) -> User,
) {
  use cached_user <- result.try(uset.lookup(uc, user.id))
  let user = new_user(cached_user)
  let _ = uset.insert(uc, user.id, user)
}

// mappers

pub fn from_user_create(user u: sql.UserCreateRow) -> User {
  User(
    id: u.id,
    username: u.username,
    first_name: u.first_name,
    last_name: u.last_name,
    bio: u.bio,
    available_for_hire: u.available_for_hire,
    premium: u.premium,
    created_at: u.created_at,
    updated_at: u.updated_at,
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
    created_at: u.created_at,
    updated_at: u.updated_at,
    storage_quota: u.storage_quota,
    storage_quota_used: u.storage_quota_used,
  )
}
