import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import youid/uuid

pub type User {
  User(
    id: uuid.Uuid,
    username: String,
    first_name: String,
    last_name: Option(String),
    bio: Option(String),
    available_for_hire: Bool,
  )
}

pub fn user_to_json(user: User) -> json.Json {
  let User(id:, username:, first_name:, last_name:, bio:, available_for_hire:) =
    user
  json.object([
    #("id", todo as "Encoder for uuid.Uuid"),
    #("username", json.string(username)),
    #("first_name", json.string(first_name)),
    #("last_name", case last_name {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("bio", case bio {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("available_for_hire", json.bool(available_for_hire)),
  ])
}

pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", todo as "Decoder for uuid.Uuid")
  use username <- decode.field("username", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use bio <- decode.field("bio", decode.optional(decode.string))
  use available_for_hire <- decode.field("available_for_hire", decode.bool)
  decode.success(User(
    id:,
    username:,
    first_name:,
    last_name:,
    bio:,
    available_for_hire:,
  ))
}
