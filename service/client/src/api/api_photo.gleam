import browser
import gleam/int
import lustre/effect.{type Effect}
import rsvp
import shared/shared_error
import shared/shared_photo
import shared/shared_privacy.{Premium, Private, Public}
import shared/shared_thumbnail

pub fn api_base_url() -> String {
  browser.window_location_origin() <> "/napi"
}

pub fn images_base_url() -> String {
  browser.window_location_origin() <> "/images"
}

pub fn fetch_thumbnail(
  on_response: fn(Result(shared_photo.Photo, rsvp.Error(shared_error.ApiError))) ->
    message,
) -> Effect(message) {
  todo
}

pub fn fetch_stats(
  on_response: fn(Result(shared_photo.Photo, rsvp.Error(shared_error.ApiError))) ->
    message,
) -> Effect(message) {
  todo
}

pub fn fetch(
  id: Int,
  on_response: fn(Result(shared_photo.Photo, rsvp.Error(String))) -> message,
) -> Effect(message) {
  let url = api_base_url() <> "/photos/" <> int.to_string(id)
  let decoder = shared_photo.photo_decoder()
  let handler = rsvp.expect_json(decoder, on_response)
  rsvp.get(url, handler)
}

pub fn data_url(thumb: shared_thumbnail.Thumbnail) {
  case thumb.privacy {
    Private -> "/images/private_photo-" <> thumb.asset_id
    Premium -> "/images/premium_photo-" <> thumb.asset_id
    Public -> "/images/photo-" <> thumb.asset_id
  }
}
