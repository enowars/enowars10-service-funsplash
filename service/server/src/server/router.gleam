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
      |> wisp.html_body("<h1>funsplash is running</h1>")
    ["@" <> user] -> profile.get(request, context, user)
    ["photos", photo_id] -> photo.get(request, context, photo_id)
    ["collections", collection] -> collection.get(request, context, collection)
    ["login"] -> auth.login(request, context)
    ["logout"] -> auth.logout(request, context)
    ["join"] -> auth.sign_up(request, context)
    ["upload"] -> photo.upload(request, context)
    ["photo-" <> photo_id] -> photo.get_data_public(request, context, photo_id)
    ["premium_photo-" <> photo_id] ->
      photo.get_data_premium(request, context, photo_id)
    // raw photo
    _ -> wisp.redirect("/")
  }
}
