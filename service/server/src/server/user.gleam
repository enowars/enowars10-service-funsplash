import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import pog
import server/sql
import shared/shared_photo
import shared/shared_user
import wisp
import youid/uuid

pub type User =
  sql.UserFindByNameRow

pub fn to_shared(
  user: User,
  photos: List(shared_photo.Photo),
) -> shared_user.User {
  //let images = list.map(image_ids, fn(id) { "./photos/" <> uuid.to_string(id) })
  shared_user.User(
    username: user.username,
    first_name: user.first_name,
    last_name: user.last_name,
    bio: user.bio,
    available_for_hire: user.available_for_hire,
    premium: user.premium,
    photos:,
  )
}

pub fn get_user(db: pog.Connection, name: String) -> Option(User) {
  // TODO: use ETP
  let user = {
    use res <- result.try(
      sql.user_find_by_name(db, name) |> result.replace_error(Nil),
    )
    list.first(res.rows)
  }
  option.from_result(user)
}
