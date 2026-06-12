import gleam/uri
import lustre/attribute

pub type Route {
  Index
  PhotoById(id: String)
  CollectionById(id: String)
  UserByName(name: String)
  Login
  Join
  Upload
  NotFound
}

pub fn parse_route(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Index
    ["photos", public_id] -> PhotoById(id: public_id)
    ["@" <> username] -> UserByName(name: username)
    ["collections", collection_id] -> CollectionById(id: collection_id)
    ["login"] -> Login
    ["join"] -> Join
    ["upload"] -> Upload
    _ -> NotFound
  }
}

pub fn to_path(route: Route) -> String {
  case route {
    Index -> "/"
    PhotoById(id:) -> "/photos/" <> id
    CollectionById(id:) -> "/collections/" <> id
    UserByName(name:) -> "/@" <> name
    Login -> "/login"
    Join -> "/join"
    Upload -> "/upload"
    NotFound -> "/404"
  }
}

pub fn href(route: Route) -> attribute.Attribute(message) {
  attribute.href(to_path(route))
}
