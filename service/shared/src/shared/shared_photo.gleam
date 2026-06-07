import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}

pub type Photo {
  Photo(
    public_id: String,
    asset_id: String,
    description: Option(String),
    title: Option(String),
    creator: String,
    premium: Bool,
    private: Bool,
    show_on_profile: Bool,
    location: Option(String),
    camera: Option(String),
    // rename to exif?
    likes_count: Int,
    views: Int,
    downloads: Int,
    created_at: Float,
    tags: List(String),
    // not properly intialized
    user_liked: Bool,
  )
}

pub fn photo_to_json(photo: Photo) -> json.Json {
  let Photo(
    public_id:,
    asset_id:,
    description:,
    title:,
    creator:,
    premium:,
    private:,
    show_on_profile:,
    location:,
    camera:,
    likes_count:,
    views:,
    downloads:,
    created_at:,
    tags:,
    user_liked:,
  ) = photo
  json.object([
    #("public_id", json.string(public_id)),
    #("asset_id", json.string(asset_id)),
    #("description", case description {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("title", case title {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("creator", json.string(creator)),
    #("premium", json.bool(premium)),
    #("private", json.bool(private)),
    #("show_on_profile", json.bool(show_on_profile)),
    #("location", case location {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("camera", case camera {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("likes_count", json.int(likes_count)),
    #("views", json.int(views)),
    #("downloads", json.int(downloads)),
    #("created_at", json.float(created_at)),
    #("tags", json.array(tags, json.string)),
    #("user_liked", json.bool(user_liked)),
  ])
}

pub fn photo_decoder() -> decode.Decoder(Photo) {
  use public_id <- decode.field("public_id", decode.string)
  use asset_id <- decode.field("asset_id", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use title <- decode.field("title", decode.optional(decode.string))
  use creator <- decode.field("creator", decode.string)
  use premium <- decode.field("premium", decode.bool)
  use private <- decode.field("private", decode.bool)
  use show_on_profile <- decode.field("show_on_profile", decode.bool)
  use location <- decode.field("location", decode.optional(decode.string))
  use camera <- decode.field("camera", decode.optional(decode.string))
  use likes_count <- decode.field("likes_count", decode.int)
  use views <- decode.field("views", decode.int)
  use downloads <- decode.field("downloads", decode.int)
  use created_at <- decode.field("created_at", decode.float)
  use tags <- decode.field("tags", decode.list(decode.string))
  use user_liked <- decode.field("user_liked", decode.bool)
  decode.success(Photo(
    public_id:,
    asset_id:,
    description:,
    title:,
    creator:,
    premium:,
    private:,
    show_on_profile:,
    location:,
    camera:,
    likes_count:,
    views:,
    downloads:,
    created_at:,
    tags:,
    user_liked:,
  ))
}
