import bravo/uset.{type USet}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import pog
import server/sql
import shared/shared_account
import shared/shared_thumbnail
import shared/shared_user.{type Error, NotFound}
import utils
import youid/uuid.{type Uuid}

pub type UserName =
  String

pub type UserId =
  Uuid

pub type UserCache =
  USet(UserId, User)

pub type ProfileCache =
  USet(UserName, Uuid)

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

pub fn update(
  user: shared_account.User,
  uid: Uuid,
  db,
  profile_cache: ProfileCache,
  user_cache: UserCache,
) -> Result(User, shared_account.Error) {
  let existing = uset.lookup(profile_cache, user.username)
  let created_user = case existing {
    // username exists in cache and doesn't belong to current user
    Ok(id) if id != uid -> Error(shared_account.UsernameExists)
    _ -> {
      case utils.db_limit(sql.user_find_by_name(db, user.username)) {
        Ok(user) -> Ok(user |> from_user_find_by_name)
        Error(_) -> {
          use inserted_user <- utils.db_limit_try(
            sql.user_update(
              db,
              uid,
              user.username,
              user.first_name,
              user.last_name |> option.unwrap(""),
              user.bio |> option.unwrap(""),
              user.available_for_hire,
            ),
            shared_account.UsernameExists,
          )
          let _ = uset.delete_key(profile_cache, user.username)
          let _ = uset.delete_key(user_cache, uid)
          Ok(inserted_user |> from_user_update)
        }
      }
    }
  }
  // TODO: make less obvious
  use new_user <- result.try(created_user)
  let real_new_user = User(..new_user, username: user.username, id: uid)
  let _ = uset.insert_new(profile_cache, user.username, new_user.id)
  let _ = uset.insert(user_cache, uid, real_new_user)
  Ok(new_user)
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
