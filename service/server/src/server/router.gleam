import gleam/http
import gleam/json
import gleam/option.{None, Some}
import server/collection
import server/web
import server/web/auth
import server/web/photo
import server/web/profile
import simplifile
import wisp

pub fn handle_request(
  request: wisp.Request,
  context: web.Context,
) -> wisp.Response {
  use request <- web.middleware(request, context)

  case wisp.path_segments(request) {
    // Auth check endpoint for the SPA
    ["me"] ->
      case context.user {
        Some(user) ->
          json.object([#("username", json.string(user.username))])
          |> json.to_string
          |> wisp.json_response(200)
        None -> wisp.response(401)
      }
    // API / server-handled routes
    ["@" <> user] ->
      case request.method {
        http.Get -> profile.get(request, context, user)
        _ -> wisp.method_not_allowed([http.Get])
      }
    ["photos", public_id] -> photo.get(request, context, public_id)
    ["collections", collection] -> collection.get(request, context, collection)
    ["login"] ->
      case request.method {
        http.Post -> auth.login(request, context)
        // GET /login -> serve SPA
        _ -> serve_spa(context)
      }
    ["logout"] -> auth.logout(request, context)
    ["join"] ->
      case request.method {
        http.Post -> auth.sign_up(request, context)
        // GET /join -> serve SPA
        _ -> serve_spa(context)
      }
    ["upload"] ->
      case request.method {
        http.Post -> photo.upload(request, context)
        // GET /upload -> serve SPA
        _ -> serve_spa(context)
      }
    ["photo-" <> asset_id] -> photo.get_data_public(request, context, asset_id)
    ["premium_photo-" <> asset_id] ->
      photo.get_data_premium(request, context, asset_id)

    // SPA routes — serve index.html and let the client-side router handle it
    [] -> serve_spa(context)
    _ -> serve_spa(context)
  }
}

fn serve_spa(context: web.Context) -> wisp.Response {
  case simplifile.read(context.static_dir <> "/index.html") {
    Ok(html) ->
      wisp.ok()
      |> wisp.html_body(html)
    Error(_) ->
      wisp.ok()
      |> wisp.html_body("<h1>🦦 🦐 funsplash is running 🦎 🐜</h1>")
  }
}
