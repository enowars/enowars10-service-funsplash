import gleam/list
import gleam/option.{None, Some}
import gleam/result
import server/collections
import server/models/photo.{type Photo}
import server/web
import youid/uuid

pub fn current_user_collections(
  context: web.Context,
  photo p: Photo,
) -> List(String) {
  case context.user {
    Some(viewer) -> {
      let values: List(String) =
        collections.get_containing_photo_from_user(
          context.state,
          p.id,
          viewer.id,
        )
        |> result.unwrap([])
        |> list.map(uuid.to_string)
      values
    }
    None -> []
  }
}
