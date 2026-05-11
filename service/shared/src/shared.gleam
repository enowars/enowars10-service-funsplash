import gleam/dynamic/decode
import youid/uuid

pub type User {
  User(id: uuid.Uuid, name: String)
}

pub type Photo {
  Photo(
    id: uuid.Uuid,
    creator_name: String,
    description: String,
    url: String,
    likes: Int,
  )
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", todo as "Decoder for uuid.Uuid")
  use name <- decode.field("name", decode.string)
  decode.success(User(id:, name:))
}
