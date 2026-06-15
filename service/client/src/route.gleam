import gleam/int
import gleam/uri
import lustre/attribute

pub type Route {
  Index
  Photo(id: String)
  Censor(id: String)
  Collection(id: Int)
  User(name: String)
  UserCollections(name: String)
  UserStats(name: String)
  Login
  Join
  Upload
  NotFound(uri: uri.Uri)
  Redirect(url: String)
}

pub fn parse(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Index
    ["@" <> username] -> User(name: username)
    ["@" <> username, "collections"] -> UserCollections(name: username)
    ["@" <> username, "stats"] -> UserStats(name: username)
    ["photos", photo_id] -> Photo(id: photo_id)
    ["photos", photo_id, "censor"] -> Censor(id: photo_id)

    ["collections", collection_id] -> {
      let result = int.parse(collection_id)
      case result {
        Ok(collection_id) -> Collection(id: collection_id)
        Error(_) -> NotFound(uri:)
      }
    }

    ["login"] -> Login
    ["join"] -> Join
    ["upload"] -> Upload
    [username] -> Redirect("/@" <> username)

    _ -> NotFound(uri:)
  }
}

pub fn href(route: Route) -> attribute.Attribute(message) {
  let url = case route {
    Index -> "/"
    Photo(id:) -> "/photos/" <> id
    Censor(id:) -> "/photos/" <> id <> "/censor"
    Collection(id:) -> "/collections/" <> int.to_string(id)
    User(name:) -> "/@" <> name
    UserCollections(name:) -> "/@" <> name <> "/collections"
    UserStats(name:) -> "/@" <> name <> "/stats"
    Login -> "/login/"
    Join -> "/join/"
    Upload -> "/upload/"
    NotFound(uri: _) -> "/404?"
    Redirect(url:) -> url
  }

  attribute.href(url)
}
