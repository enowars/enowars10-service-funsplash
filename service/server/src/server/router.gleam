import gleam/http
import server/context
import server/photo
import server/user
import wisp

pub fn middleware(
  req,
  context: context.Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) {
  use <- wisp.log_request(req)
  use <- wisp.serve_static(req, under: "/static", from: context.static_dir)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  handle_request(req)
}

pub fn handle_request(
  request: wisp.Request,
  context: context.Context,
) -> wisp.Response {
  use req <- middleware(request, context)

  case wisp.path_segments(req) {
    [] -> todo
    ["@" <> user] -> user.get(request, context, user)
    ["photos", photo] -> photo.get(request, context, photo)
    ["login"] -> user.login(request, context)
    ["signup"] -> user.signup(request, context)
    [username] -> wisp.redirect("@" <> username)
    _ -> wisp.redirect("/")
  }
}
