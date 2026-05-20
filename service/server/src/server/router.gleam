import server/collection
import server/photo
import server/user
import server/web
import server/web/auth
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
    ["@" <> user] -> user.get(request, user)
    ["photos", photo] -> photo.get(request, context, photo)
    ["collections", collection] -> collection.get(request, context, collection)
    ["login"] -> auth.login(request, context)
    ["join"] -> auth.sign_up(request, context)
    ["upload"] -> photo.upload(request, context)

    _ -> wisp.redirect("/")
  }
}
