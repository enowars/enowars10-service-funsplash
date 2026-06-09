import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import server/photo
import server/sql
import server/user.{type User}
import server/web
import shared/shared_user
import wisp

pub fn get(
  request: wisp.Request,
  context: web.Context,
  username: String,
) -> wisp.Response {
  let user = case context.user {
    Some(user) if user.username == username ->
      get_own(request, context, username)
    _ -> get_other(request, context, username)
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

// TODO: pagination
fn get_own(request: wisp.Request, context: web.Context, username: String) {
  todo
}

fn get_other(request: wisp.Request, context: web.Context, username: String) {
  use user <- result.try(option.to_result(
    user.get_by_name(context.db, username),
    Nil,
  ))
  use photos <- result.try(
    sql.photos_list_by_user(context.db, user.id, True)
    // TODO: do case for logged in premium etc.
    |> result.replace_error(Nil),
  )
  let photos =
    list.map(photos.rows, fn(photo) {
      photo
      |> photo.from_photos_list_by_user_row
      |> photo.to_shared(user.username, [], False)
    })
  Ok(user.to_shared(user, photos))
}
