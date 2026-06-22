import api/api_photo
import auth.{type Auth}
import gleam/int
import gleam/list
import gleam/option
import lustre/attribute.{alt, class, src}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{a, button, div, h1, img, p, span}
import lustre/event
import route
import rsvp
import shared/shared_photo
import shared/shared_privacy
import shared/shared_stats

// MODEL -----------------------------------------------------------------------

pub type Model {
  Loading
  Loaded(photo: shared_photo.Photo, liked: Bool)
  Failed
}

pub fn init(id: String) -> #(Model, Effect(Message)) {
  let effect = api_photo.fetch(id, ApiReturnedPhoto)
  #(Loading, effect)
}

// UPDATE ----------------------------------------------------------------------

pub type Message {
  ApiReturnedPhoto(Result(shared_photo.Photo, rsvp.Error(String)))
  UserClickedLike
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message, model {
    ApiReturnedPhoto(Ok(photo)), _ -> #(
      Loaded(photo, liked: photo.thumbnail.user_liked),
      effect.none(),
    )
    ApiReturnedPhoto(_), _ -> #(Failed, effect.none())
    UserClickedLike, Loaded(photo, liked) -> {
      let new_liked = !liked
      let delta = case new_liked {
        True -> 1
        False -> -1
      }
      let new_stats =
        shared_stats.Stats(..photo.stats, likes: photo.stats.likes + delta)
      #(
        Loaded(shared_photo.Photo(..photo, stats: new_stats), new_liked),
        effect.none(),
      )
    }
    _, _ -> #(model, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model, auth: Auth) -> Element(Message) {
  div([class("max-w-4xl mx-auto py-8 px-4")], [
    case model {
      Loading -> loading_view()
      Loaded(photo, liked) -> photo_view(photo, liked, auth)
      Failed -> error_view()
    },
  ])
}

fn loading_view() -> Element(Message) {
  div([class("flex justify-center py-20")], [
    p([class("text-gray-400 text-sm")], [text("Loading…")]),
  ])
}

fn error_view() -> Element(Message) {
  div([class("flex justify-center py-20")], [
    p([class("text-red-500 text-sm")], [text("Photo not found.")]),
  ])
}

fn photo_view(
  photo: shared_photo.Photo,
  liked: Bool,
  auth: Auth,
) -> Element(Message) {
  let is_owner = case auth {
    auth.LoggedIn(user) -> user.username == photo.thumbnail.creator
    _ -> False
  }

  div([class("space-y-6")], [
    // Header with creator
    div([class("flex items-center justify-between")], [
      div([class("flex items-center gap-3")], [
        a(
          [
            route.href(route.User(photo.thumbnail.creator)),
            class("text-sm font-medium text-gray-800 hover:text-black"),
          ],
          [text(photo.thumbnail.creator)],
        ),
        case photo.thumbnail.privacy {
          shared_privacy.Premium ->
            span(
              [
                class(
                  "bg-yellow-100 text-yellow-800 text-[10px] font-bold px-2 py-0.5 rounded",
                ),
              ],
              [text("PREMIUM")],
            )
          shared_privacy.Private ->
            span(
              [
                class(
                  "bg-red-100 text-red-800 text-[10px] font-bold px-2 py-0.5 rounded",
                ),
              ],
              [text("PRIVATE")],
            )
          shared_privacy.Public -> element.none()
        },
        case photo.thumbnail.show_on_profile {
          False ->
            span(
              [
                class(
                  "bg-gray-200 text-gray-800 text-[10px] font-bold px-2 py-0.5 rounded",
                ),
              ],
              [text("HIDDEN FROM PROFILE")],
            )
          True -> element.none()
        },
      ]),
      div([class("flex items-center gap-2")], [
        case is_owner {
          True ->
            a(
              [
                route.href(route.Censor(photo.thumbnail.public_id)),
                class(
                  "flex items-center gap-1 rounded-md border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-100",
                ),
              ],
              [text("Censor Image")],
            )
          False -> element.none()
        },
        case auth.is_logged_in(auth) {
          True ->
            button(
              [
                event.on_click(UserClickedLike),
                class(case liked {
                  True ->
                    "flex items-center gap-1 rounded-md border border-red-300 bg-red-50 px-3 py-1.5 text-sm font-medium text-red-600 hover:bg-red-100"
                  False ->
                    "flex items-center gap-1 rounded-md border border-gray-300 px-3 py-1.5 text-sm font-medium text-gray-600 hover:bg-gray-50"
                }),
              ],
              [
                text(case liked {
                  True -> "♥ Liked"
                  False -> "♡ Like"
                }),
              ],
            )
          False -> element.none()
        },
      ]),
    ]),
    // Photo image
    img([
      src(api_photo.src_url(photo.thumbnail, auth)),
      alt(case photo.description {
        option.Some(t) -> t
        option.None -> "Photo"
      }),
      class("w-full rounded-lg"),
    ]),
    // Description
    case photo.thumbnail.description {
      option.Some(desc) -> p([class("text-sm text-gray-600")], [text(desc)])
      option.None -> element.none()
    },
    // Stats row
    div([class("flex gap-6 text-sm text-gray-500")], [
      stat("Views", photo.stats.views),
      stat("Likes", photo.stats.likes),
      stat("Downloads", photo.stats.downloads),
    ]),
    // Details
    case photo.location {
      option.Some(loc) ->
        p([class("text-sm text-gray-500")], [text("📍 " <> loc)])
      option.None -> element.none()
    },
    case photo.camera {
      option.Some(cam) ->
        p([class("text-sm text-gray-500")], [text("📷 " <> cam)])
      option.None -> element.none()
    },
    // Tags
    case photo.tags {
      [] -> element.none()
      tags ->
        div(
          [class("flex flex-wrap gap-2")],
          list.map(tags, fn(tag) {
            span(
              [
                class(
                  "rounded-full bg-gray-100 px-3 py-1 text-xs text-gray-600",
                ),
              ],
              [text(tag)],
            )
          }),
        )
    },
  ])
}

fn stat(label: String, value: Int) -> Element(msg) {
  span([], [
    span([class("font-medium text-gray-800")], [text(int.to_string(value))]),
    text(" " <> label),
  ])
}
