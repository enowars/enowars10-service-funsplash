import gleam/int
import gleam/uri
import lustre/attribute

pub type Route {
  Index
  Photo(id: Int)
  Collection(id: Int)
  User(name: String)
  UserCollections(name: String)
  UserStats(name: String)
  Login
  Join
  NotFound(uri: uri.Uri)
}

pub fn parse(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Index
    ["@", username] -> User(name: username)
    ["@", username, "collections"] -> UserCollections(name: username)
    ["@", username, "stats"] -> UserStats(name: username)
    ["photos", photo_id] ->
      case int.parse(photo_id) {
        Ok(photo_id) -> Photo(id: photo_id)
        Error(_) -> NotFound(uri:)
      }

    ["collections", collection_id] -> {
      let result = int.parse(collection_id)
      case result {
        Ok(collection_id) -> Collection(id: collection_id)
        Error(_) -> NotFound(uri:)
      }
    }

    ["login"] -> Login
    ["join"] -> Join
    [username] -> User(username)

    _ -> NotFound(uri:)
  }
}

pub fn href(route: Route) -> attribute.Attribute(message) {
  let url = case route {
    Index -> "/"
    Photo(id:) -> "/photos/" <> int.to_string(id)
    Collection(id:) -> "/collections/" <> int.to_string(id)
    User(name:) -> "/@/" <> name
    UserCollections(name:) -> "/@/" <> name <> "/collections"
    UserStats(name:) -> "/@/" <> name <> "/stats"
    Login -> "/login/"
    Join -> "/join/"
    NotFound(uri: _) -> "/404?"
  }

  attribute.href(url)
}
