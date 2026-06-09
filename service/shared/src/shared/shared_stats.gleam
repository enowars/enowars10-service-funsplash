import gleam/dynamic/decode
import gleam/json
import shared/shared_thumbnail

pub type StatsThumbnail {
  StatsThumbnail(
    thumbnail: shared_thumbnail.Thumbnail,
    views: Int,
    downloads: Int,
  )
}

fn stats_thumbnail_to_json(stats_thumbnail: StatsThumbnail) -> json.Json {
  let StatsThumbnail(thumbnail:, views:, downloads:) = stats_thumbnail
  json.object([
    #("thumbnail", shared_thumbnail.thumbnail_to_json(thumbnail)),
    #("views", json.int(views)),
    #("downloads", json.int(downloads)),
  ])
}

fn stats_thumbnail_decoder() -> decode.Decoder(StatsThumbnail) {
  use thumbnail <- decode.field(
    "thumbnail",
    shared_thumbnail.thumbnail_decoder(),
  )
  use views <- decode.field("views", decode.int)
  use downloads <- decode.field("downloads", decode.int)
  decode.success(StatsThumbnail(thumbnail:, views:, downloads:))
}
