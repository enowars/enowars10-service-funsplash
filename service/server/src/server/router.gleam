import gleam/http
import gleam/http/request
import gleam/http/response
import mist
import server/collection
import server/context
import server/photo
import server/user
import wisp

pub fn middleware(
  req: wisp.Request,
  context: context.Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.serve_static(req, under: "/static", from: context.static_dir)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  handle_request(req)
}

pub fn wisp_handler(
  request: wisp.Request,
  context: context.Context,
) -> wisp.Response {
  use req <- middleware(request, context)

  case wisp.path_segments(req) {
    [] -> todo
    ["@" <> user] -> user.get(request, context, user)
    ["photos", photo] -> photo.get(request, context, photo)
    ["collections", collection] -> collection.get(request, context, collection)
    ["login"] -> user.login(request, context)
    ["join"] -> user.join(request, context)
    ["upload"] -> photo.upload(request, context)

    _ -> wisp.redirect("/")
  }
}
