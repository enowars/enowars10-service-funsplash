import bravo/uset
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/result
import server/photo
import server/sql
import server/user.{type User}
import server/web
import shared/shared_user.{NotFound, PhotosNotFound}
import utils
import wisp

// TODO: use uname cookie and compare with that. also think about doing pw check
pub fn get(
  request: wisp.Request,
  context: web.Context,
  username: String,
) -> wisp.Response {
  let user = {
    let user = case uset.lookup(context.profile_cache, username) {
      Ok(uid) ->
        case uset.lookup(context.user_cache, uid) {
          Ok(user) -> Ok(user)
          Error(_) -> {
            use user <- result.try(user.get_by_id(context.db, uid))
            let _ = uset.insert(context.user_cache, user.id, user)
            Ok(user)
          }
        }
      Error(_) -> {
        use user <- utils.db_limit(
          sql.user_find_by_name(context.db, username),
          NotFound,
        )
        let user = user |> user.from_user_find_by_name
        let _ = uset.insert(context.profile_cache, user.username, user.id)
        let _ = uset.insert(context.user_cache, user.id, user)
        Ok(user)
      }
    }
    use user <- utils.result_guard(user, Error(NotFound))

    case context.user {
      Some(context_user) if user.id == context_user.id ->
        get_own(request, context, user)
      _ -> get_other(request, context, user)
    }
  }

  case user {
    Ok(user) ->
      wisp.json_response(
        shared_user.user_to_json(user) |> json.to_string(),
        200,
      )
    _ -> wisp.bad_request("error")
  }
}

// TODO: change to most recent 3 for pagination
// TODO: use cache
fn get_own(_request: wisp.Request, context: web.Context, user: User) {
  use photos <- result.try(
    sql.photos_list_by_owner(context.db, user.id)
    |> result.replace_error(PhotosNotFound),
  )

  let photos =
    list.map(photos.rows, fn(photo) {
      photo
      |> photo.from_photos_list_by_owner_row
      |> photo.to_shared_thumbnail(user.username, False)
    })

  Ok(user.to_shared(user, photos))
}

fn get_other(_request: wisp.Request, context: web.Context, user: User) {
  use photos <- result.try(
    sql.photos_list_by_user(context.db, user.id)
    |> result.replace_error(PhotosNotFound),
  )
  let photos =
    list.map(photos.rows, fn(photo) {
      photo
      |> photo.from_photos_list_by_user_row
      |> photo.to_shared_thumbnail(user.username, False)
    })
  Ok(user.to_shared(user, photos))
}
