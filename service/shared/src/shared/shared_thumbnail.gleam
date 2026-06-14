import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import shared/shared_privacy.{type Privacy}

pub type Thumbnail {
  Thumbnail(
    public_id: String,
    asset_id: String,
    description: Option(String),
    creator: String,
    privacy: Privacy,
    user_liked: Bool,
    show_on_profile: Bool,
  )
}

pub fn thumbnail_to_json(thumbnail: Thumbnail) -> json.Json {
  let Thumbnail(
    public_id:,
    asset_id:,
    description:,
    creator:,
    privacy:,
    user_liked:,
    show_on_profile:,
  ) = thumbnail
  json.object([
    #("public_id", json.string(public_id)),
    #("asset_id", json.string(asset_id)),
    #("description", case description {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("creator", json.string(creator)),
    #("privacy", shared_privacy.privacy_to_json(privacy)),
    #("user_liked", json.bool(user_liked)),
    #("show_on_profile", json.bool(show_on_profile)),
  ])
}

pub fn thumbnail_decoder() -> decode.Decoder(Thumbnail) {
  use public_id <- decode.field("public_id", decode.string)
  use asset_id <- decode.field("asset_id", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use creator <- decode.field("creator", decode.string)
  use privacy <- decode.field("privacy", shared_privacy.privacy_decoder())
  use user_liked <- decode.field("user_liked", decode.bool)
  use show_on_profile <- decode.field("show_on_profile", decode.bool)
  decode.success(Thumbnail(
    public_id:,
    asset_id:,
    description:,
    creator:,
    privacy:,
    user_liked:,
    show_on_profile:,
  ))
}
