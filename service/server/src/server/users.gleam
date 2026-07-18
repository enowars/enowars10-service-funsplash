import bravo/uset
import gleam/list
import gleam/option
import gleam/result
import server/models/photo
import server/models/user.{type User, User}
import server/sql
import server/state.{type State}
import shared/shared_account
import shared/shared_user.{type Error, NotFound}
import utils
import youid/uuid.{type Uuid}

pub fn get_likes(state: State, user_id id: user.Id) -> List(photo.Id) {
  case uset.lookup(state.user_likes_cache, id) {
    Ok(likes) -> likes
    Error(_) -> {
      use res <- utils.result_guard(sql.user_list_likes(state.db, id), [])
      let pids = res.rows |> list.map(fn(row) { row.photo_id })
      let _ = uset.insert(state.user_likes_cache, id, pids)
      pids
    }
  }
}

pub fn get_by_id(state: State, user_id id: user.Id) -> Result(User, Error) {
  utils.get_cache_l0(
    state.user_cache,
    id,
    sql.user_find_by_id(state.db, _),
    user.from_find_by_id,
    NotFound,
  )
}

pub fn get_by_name(
  state state: State,
  username name: String,
) -> Result(User, Error) {
  utils.get_cache_l1(
    state.profile_cache,
    state.user_cache,
    name,
    sql.user_find_by_name(state.db, _),
    fn(u) { u.id },
    user.from_find_by_name,
    NotFound,
  )
}

pub fn search(state: State, username: String) -> List(shared_user.User) {
  {
    use res <- result.try(
      sql.user_search(state.db, username) |> result.replace_error(Nil),
    )
    use first <- result.try(list.first(res.rows))
    // insert_new fails if already exists so this is safe
    let _ = uset.insert_new(state.profile_cache, first.username, first.id)
    Ok(
      list.map(res.rows, fn(row) { row |> user.from_search |> user.to_shared }),
    )
  }
  |> result.unwrap([])
}

pub fn update(
  user: shared_account.User,
  uid: Uuid,
  state: State,
) -> Result(User, shared_account.Error) {
  evict_user_entries(state, user.username, uid)
  case apply_user_update(state, user, uid) {
    Ok(updated) -> Ok(populate_user_cache(state, user, uid, updated))
    Error(_) -> warm_user_cache(state, user, uid)
  }
}

fn evict_user_entries(state: State, _username: String, uid: Uuid) -> Nil {
  let _ = uset.delete_key(state.user_cache, uid)
  Nil
}

fn apply_user_update(
  state: State,
  user: shared_account.User,
  uid: Uuid,
) -> Result(User, shared_account.Error) {
  use inserted_user <- utils.db_limit_try(
    sql.user_update(
      state.db,
      uid,
      user.username,
      user.first_name,
      user.last_name |> option.unwrap(""),
      user.bio |> option.unwrap(""),
      user.available_for_hire,
    ),
    shared_account.UsernameExists,
  )
  Ok(inserted_user |> user.from_update)
}

fn populate_user_cache(
  state: State,
  user: shared_account.User,
  uid: Uuid,
  new_user: User,
) -> User {
  let full_user = User(..new_user, username: user.username, id: uid)
  let _ = uset.insert_new(state.profile_cache, user.username, uid)
  let _ = uset.insert(state.user_cache, uid, full_user)
  full_user
}

fn warm_user_cache(
  state: State,
  user: shared_account.User,
  uid: Uuid,
) -> Result(User, shared_account.Error) {
  use existing_row <- utils.db_limit_try(
    sql.user_find_by_name(state.db, user.username),
    shared_account.UsernameExists,
  )
  let existing = existing_row |> user.from_find_by_name
  case uset.insert_new(state.profile_cache, user.username, existing.id) {
    Ok(_) -> {
      let cached = User(..existing, username: user.username, id: uid)
      let _ = uset.insert(state.user_cache, uid, cached)
      let _ = sql.user_find_by_id(state.db, existing.id)
      let _ = uset.delete_key(state.profile_cache, user.username)
      let _ = uset.delete_key(state.user_cache, uid)
      Ok(existing)
    }
    Error(_) -> Ok(existing)
  }
}
