import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import server/photo
import server/sql
import server/user
import server/web
import shared/shared_user
import wisp

pub fn get(
  request: wisp.Request,
  context: web.Context,
  user: String,
) -> wisp.Response {
  let user = {
    use res <- result.try(
      sql.user_find_by_name(context.db, user) |> result.replace_error(Nil),
    )
    use user <- result.try(list.first(res.rows))
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

  case user {
    Ok(user) ->
      wisp.json_response(
        shared_user.user_to_json(user) |> json.to_string(),
        200,
      )
    _ -> wisp.bad_request("error")
  }
}
