import gleam/int
import gleam/uri
import lustre/attribute

type Route {
  Index
  PhotoById(id: Int)
  CollectionById(id: Int)
  UserByName(name: String)
  Login
  Join
  NotFound(uri: uri.Uri)
}

fn parse_route(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Index

    ["photo", photo_id] ->
      case int.parse(photo_id) {
        Ok(photo_id) -> PhotoById(id: photo_id)
        Error(_) -> NotFound(uri:)
      }

    ["@", username] -> UserByName(name: username)

    ["collection", collection_id] ->
      case int.parse(collection_id) {
        Ok(collection_id) -> CollectionById(id: collection_id)
        Error(_) -> NotFound(uri:)
      }

    ["login"] -> Login
    ["join"] -> Join
    [username] -> UserByName(username)

    _ -> NotFound(uri:)
  }
}

fn href(route: Route) -> attribute.Attribute(message) {
  let url = case route {
    Index -> "/"
    PhotoById(id:) -> "/photos/" <> int.to_string(id)
    CollectionById(id:) -> "/collections/" <> int.to_string(id)
    UserByName(name:) -> "/@/" <> name
    Login -> "/login/"
    Join -> "/join/"
    NotFound(uri:) -> "/404"
  }

  attribute.href(url)
}
