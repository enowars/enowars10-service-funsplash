import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import youid/uuid

pub type Image {
  Image(
    id: uuid.Uuid,
    description: Option(String),
    creator_username: String,
    creator_display_name: String,
    url: String,
    likes: Int,
    views: Int,
    downloads: Int,
    published: Timestamp,
    camera: Option(String),
    premium: Bool,
    private: Bool,
    tags: List(String),
    created_at: Timestamp,
  )
}

pub fn image_to_json(image: Image) -> json.Json {
  let Image(
    id:,
    description:,
    creator_username:,
    creator_display_name:,
    url:,
    likes:,
    views:,
    downloads:,
    published:,
    camera:,
    premium:,
    private:,
    tags:,
    created_at:,
  ) = image
  json.object([
    #("id", todo as "Encoder for uuid.Uuid"),
    #("description", case description {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("creator_username", json.string(creator_username)),
    #("creator_display_name", json.string(creator_display_name)),
    #("url", json.string(url)),
    #("likes", json.int(likes)),
    #("views", json.int(views)),
    #("downloads", json.int(downloads)),
    #("published", todo as "Encoder for Timestamp"),
    #("camera", case camera {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("premium", json.bool(premium)),
    #("private", json.bool(private)),
    #("tags", json.array(tags, json.string)),
    #("created_at", todo as "Encoder for Timestamp"),
  ])
}

pub fn image_decoder() -> decode.Decoder(Image) {
  use id <- decode.field("id", todo as "Decoder for uuid.Uuid")
  use description <- decode.field("description", decode.optional(decode.string))
  use creator_username <- decode.field("creator_username", decode.string)
  use creator_display_name <- decode.field(
    "creator_display_name",
    decode.string,
  )
  use url <- decode.field("url", decode.string)
  use likes <- decode.field("likes", decode.int)
  use views <- decode.field("views", decode.int)
  use downloads <- decode.field("downloads", decode.int)
  use published <- decode.field("published", todo as "Decoder for Timestamp")
  use camera <- decode.field("camera", decode.optional(decode.string))
  use premium <- decode.field("premium", decode.bool)
  use private <- decode.field("private", decode.bool)
  use tags <- decode.field("tags", decode.list(decode.string))
  use created_at <- decode.field("created_at", todo as "Decoder for Timestamp")
  decode.success(Image(
    id:,
    description:,
    creator_username:,
    creator_display_name:,
    url:,
    likes:,
    views:,
    downloads:,
    published:,
    camera:,
    premium:,
    private:,
    tags:,
    created_at:,
  ))
}
