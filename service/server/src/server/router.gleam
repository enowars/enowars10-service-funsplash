import gleam/http
import server/web
import server/web/account
import server/web/auth
import server/web/collection
import server/web/photo
import server/web/user
import simplifile
import wisp

pub fn handle_request(
  request: wisp.Request,
  context: web.Context,
) -> wisp.Response {
  use request <- web.middleware(request, context)

  case wisp.path_segments(request) {
    ["napi", ..api] ->
      case api {
        ["s", "users", username] -> user.search(request, context, username)
        ["users", username] -> user.get(request, context, username)
        ["users", username, "photos"] ->
          user.get_photos(request, context, username)
        ["users", username, "collections"] ->
          user.get_collections(request, context, username)
        ["photos", public_id] -> photo.get(request, context, public_id)
        ["login"] -> auth.login(request, context)
        ["logout"] -> auth.logout(request, context)
        ["join"] -> auth.sign_up(request, context)
        ["upload"] -> photo.upload(request, context)
        ["like", public_id] -> photo.like(request, context, public_id)
        ["account"] -> account.update(request, context)
        ["account", "password"] -> account.change_password(request, context)
        ["me"] -> auth.me(request, context)
        ["collections", ..path] -> {
          case path {
            [] -> collection.create(request, context)
            [col_id] -> collection.get(request, context, col_id)
            [col_id, "photos"] -> collection.photos(request, context, col_id)
            [col_id, "add", photo_id] ->
              collection.add_photo(request, context, col_id, photo_id)
            [col_id, "remove", photo_id] ->
              collection.remove_photo(request, context, col_id, photo_id)
            _ -> wisp.not_found()
          }
        }
        _ -> wisp.not_found()
      }
    ["images", ..images] ->
      case images {
        ["photo-" <> asset_id] ->
          photo.get_data_public(request, context, asset_id)
        ["premium_photo-" <> asset_id] ->
          photo.get_data_premium(request, context, asset_id)
        ["private_photo-" <> asset_id] ->
          photo.get_data_private(request, context, asset_id)
        _ -> wisp.not_found()
      }
    _ if request.method == http.Get -> serve_index(context)
    _ -> wisp.not_found()
  }
}

fn serve_index(context: web.Context) -> wisp.Response {
  case simplifile.read(context.state.static_dir <> "/index.html") {
    Ok(html) -> wisp.ok() |> wisp.html_body(html)
    Error(_) -> wisp.internal_server_error()
  }
}
