import server/collection
import server/web
import server/web/auth
import server/web/photo
import server/web/profile
import wisp

pub fn handle_request(
  request: wisp.Request,
  context: web.Context,
) -> wisp.Response {
  use request <- web.middleware(request, context)

  case wisp.path_segments(request) {
    [] ->
      wisp.ok()
      |> wisp.html_body("<h1>🦦 🦐 funsplash is running 🦎 🐜</h1>")
    ["napi", ..api] ->
      case api {
        ["users", user] -> profile.get(request, context, user)
        ["photos", public_id] -> photo.get(request, context, public_id)
        ["collections", collection] ->
          collection.get(request, context, collection)
        ["login"] -> auth.login(request, context)
        ["logout"] -> auth.logout(request, context)
        ["join"] -> auth.sign_up(request, context)
        ["upload"] -> photo.upload(request, context)
        _ -> wisp.not_found()
      }
    ["images", ..images] ->
      case images {
        ["photo-" <> asset_id] ->
          photo.get_data_public(request, context, asset_id)
        ["premium_photo-" <> asset_id] ->
          photo.get_data_premium(request, context, asset_id)
        ["private_photo-" <> _asset_id] -> wisp.not_found()
        _ -> wisp.not_found()
      }
    _ -> wisp.not_found()
  }
}
