import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import shared/shared_stats
import shared/shared_thumbnail

pub type Photo {
  Photo(
    thumbnail: shared_thumbnail.Thumbnail,
    stats: shared_stats.Stats,
    title: Option(String),
    location: Option(String),
    camera: Option(String),
    created_at: Float,
    tags: List(String),
  )
}

pub fn photo_to_json(photo: Photo) -> json.Json {
  let Photo(thumbnail:, stats:, title:, location:, camera:, created_at:, tags:) =
    photo
  json.object([
    #("thumbnail", shared_thumbnail.thumbnail_to_json(thumbnail)),
    #("stats", shared_stats.stats_to_json(stats)),
    #("title", case title {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("location", case location {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("camera", case camera {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("created_at", json.float(created_at)),
    #("tags", json.array(tags, json.string)),
  ])
}

pub fn photo_decoder() -> decode.Decoder(Photo) {
  use thumbnail <- decode.field(
    "thumbnail",
    shared_thumbnail.thumbnail_decoder(),
  )
  use stats <- decode.field("stats", shared_stats.stats_decoder())
  use title <- decode.field("title", decode.optional(decode.string))
  use location <- decode.field("location", decode.optional(decode.string))
  use camera <- decode.field("camera", decode.optional(decode.string))
  use created_at <- decode.field("created_at", decode.float)
  use tags <- decode.field("tags", decode.list(decode.string))
  decode.success(Photo(
    thumbnail:,
    stats:,
    title:,
    location:,
    camera:,
    created_at:,
    tags:,
  ))
}
