import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}

pub type Thumbnail {
  Thumbnail(
    public_id: String,
    asset_id: String,
    creator: String,
    premium: Bool,
    private: Bool,
    user_liked: Bool,
    show_on_profile: Bool,
  )
}

pub fn thumbnail_to_json(thumbnail: Thumbnail) -> json.Json {
  let Thumbnail(
    public_id:,
    asset_id:,
    creator:,
    premium:,
    private:,
    user_liked:,
    show_on_profile:,
  ) = thumbnail
  json.object([
    #("public_id", json.string(public_id)),
    #("asset_id", json.string(asset_id)),
    #("creator", json.string(creator)),
    #("premium", json.bool(premium)),
    #("private", json.bool(private)),
    #("user_liked", json.bool(user_liked)),
    #("show_on_profile", json.bool(show_on_profile)),
  ])
}

pub fn thumbnail_decoder() -> decode.Decoder(Thumbnail) {
  use public_id <- decode.field("public_id", decode.string)
  use asset_id <- decode.field("asset_id", decode.string)
  use creator <- decode.field("creator", decode.string)
  use premium <- decode.field("premium", decode.bool)
  use private <- decode.field("private", decode.bool)
  use user_liked <- decode.field("user_liked", decode.bool)
  use show_on_profile <- decode.field("show_on_profile", decode.bool)
  decode.success(Thumbnail(
    public_id:,
    asset_id:,
    creator:,
    premium:,
    private:,
    user_liked:,
    show_on_profile:,
  ))
}
