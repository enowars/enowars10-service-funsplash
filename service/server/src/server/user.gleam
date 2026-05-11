import gleam/http
import server/context
import wisp

pub fn get(request: wisp.Request, context: context.Context, user: String) -> a {
  todo
}

pub fn signup(request: wisp.Request, context: context.Context) -> wisp.Response {
  case request.method {
    http.Get -> todo
    http.Post -> todo
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

pub fn login(request: wisp.Request, context: context.Context) -> wisp.Response {
  case request.method {
    http.Get -> todo
    http.Post -> todo
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}
