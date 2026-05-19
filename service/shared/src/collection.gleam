import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import youid/uuid

pub type Collection {
  Collection(
    id: uuid.Uuid,
    name: String,
    creator_username: String,
    creator_display_name: String,
    description: Option(String),
    images: List(uuid.Uuid),
    created_at: Timestamp,
    private: Bool,
  )
}

pub fn collection_to_json(collection: Collection) -> json.Json {
  let Collection(
    id:,
    name:,
    creator_username:,
    creator_display_name:,
    description:,
    images:,
    created_at:,
    private:,
  ) = collection
  json.object([
    #("id", todo as "Encoder for uuid.Uuid"),
    #("name", json.string(name)),
    #("creator_username", json.string(creator_username)),
    #("creator_display_name", json.string(creator_display_name)),
    #("description", case description {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("images", json.array(images, todo as "Encoder for uuid.Uuid")),
    #("created_at", todo as "Encoder for Timestamp"),
    #("private", json.bool(private)),
  ])
}

pub fn collection_decoder() -> decode.Decoder(Collection) {
  use id <- decode.field("id", todo as "Decoder for uuid.Uuid")
  use name <- decode.field("name", decode.string)
  use creator_username <- decode.field("creator_username", decode.string)
  use creator_display_name <- decode.field(
    "creator_display_name",
    decode.string,
  )
  use description <- decode.field("description", decode.optional(decode.string))
  use images <- decode.field(
    "images",
    decode.list(todo as "Decoder for uuid.Uuid"),
  )
  use created_at <- decode.field("created_at", todo as "Decoder for Timestamp")
  use private <- decode.field("private", decode.bool)
  decode.success(Collection(
    id:,
    name:,
    creator_username:,
    creator_display_name:,
    description:,
    images:,
    created_at:,
    private:,
  ))
}
