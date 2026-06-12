import gleam/int
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import shared/shared_photo
import shared/shared_routes
import shared/shared_thumbnail

pub type Model {
  NotLoaded
  Loading
  Loaded(shared_photo.Photo)
  Error
}

pub fn view(model: Model) -> Element(msg) {
  html.div([attribute.class("page-enter")], [
    case model {
      NotLoaded | Loading -> loading_view()
      Loaded(photo) -> photo_view(photo)
      Error -> error_view()
    },
  ])
}

fn loading_view() -> Element(msg) {
  html.div(
    [attribute.class("max-w-5xl mx-auto px-4 py-12 animate-pulse-soft")],
    [
      html.div([attribute.class("skeleton w-full h-96 mb-8")], []),
      html.div([attribute.class("skeleton w-1/2 h-6 mb-4")], []),
      html.div([attribute.class("skeleton w-1/3 h-4")], []),
    ],
  )
}

fn error_view() -> Element(msg) {
  html.div(
    [
      attribute.class(
        "max-w-2xl mx-auto px-4 py-24 text-center animate-fade-in",
      ),
    ],
    [
      html.div([attribute.class("text-6xl mb-6")], [element.text("😕")]),
      html.h1(
        [attribute.class("text-2xl font-bold text-primary mb-3")],
        [element.text("Photo not found")],
      ),
      html.p([attribute.class("text-accent mb-8")], [
        element.text("This photo may have been removed or doesn't exist."),
      ]),
      html.a(
        [
          attribute.href("/"),
          attribute.class(
            "inline-block px-6 py-2.5 bg-primary text-white rounded-lg hover:bg-primary-hover transition-colors text-sm font-medium",
          ),
        ],
        [element.text("← Back to home")],
      ),
    ],
  )
}

fn photo_view(photo: shared_photo.Photo) -> Element(msg) {
  let thumb = photo.thumbnail
  let stats = photo.stats
  let image_url = photo_image_url(thumb)

  html.div([attribute.class("max-w-5xl mx-auto px-4 py-8 animate-fade-in")], [
    // Header bar
    html.div(
      [attribute.class("flex items-center justify-between mb-6")],
      [
        // Creator info
        html.a(
          [
            attribute.href("/@" <> thumb.creator),
            attribute.class("flex items-center gap-3 group"),
          ],
          [
            html.div(
              [
                attribute.class(
                  "w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center text-lg font-bold text-accent",
                ),
              ],
              [element.text("👤")],
            ),
            html.div([], [
              html.p(
                [
                  attribute.class(
                    "text-sm font-medium text-primary group-hover:underline",
                  ),
                ],
                [element.text(thumb.creator)],
              ),
              case thumb.premium {
                True ->
                  html.span(
                    [
                      attribute.class(
                        "text-xs text-premium font-medium",
                      ),
                    ],
                    [element.text("★ Premium")],
                  )
                False -> element.none()
              },
            ]),
          ],
        ),
        // Actions
        html.div([attribute.class("flex items-center gap-3")], [
          // Like indicator
          html.div(
            [
              attribute.class(
                "flex items-center gap-1.5 px-4 py-2 border border-border rounded-lg text-sm text-accent",
              ),
            ],
            [
              html.span([], [
                element.text(case thumb.user_liked {
                  True -> "❤️"
                  False -> "🤍"
                }),
              ]),
              element.text(int.to_string(stats.likes)),
            ],
          ),
          // Download link
          html.a(
            [
              attribute.href(image_url),
              attribute.attribute("download", ""),
              attribute.class(
                "flex items-center gap-1.5 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-hover transition-colors text-sm font-medium",
              ),
            ],
            [
              html.span([], [element.text("⬇")]),
              element.text("Download"),
            ],
          ),
        ]),
      ],
    ),
    // Main image
    html.div([attribute.class("rounded-xl overflow-hidden bg-gray-100 mb-8")], [
      html.img([
        attribute.src(image_url),
        attribute.alt(
          thumb.description |> option.unwrap("Photo on funsplash"),
        ),
        attribute.class("w-full h-auto max-h-[75vh] object-contain mx-auto"),
      ]),
    ]),
    // Details grid
    html.div([attribute.class("grid grid-cols-1 md:grid-cols-3 gap-8")], [
      // Left: metadata
      html.div([attribute.class("md:col-span-2 space-y-4")], [
        case photo.title {
          option.Some(title) ->
            html.h1(
              [attribute.class("text-2xl font-bold text-primary")],
              [element.text(title)],
            )
          option.None -> element.none()
        },
        case photo.thumbnail.description {
          option.Some(desc) ->
            html.p(
              [attribute.class("text-accent leading-relaxed")],
              [element.text(desc)],
            )
          option.None -> element.none()
        },
        // Tags
        case list.is_empty(photo.tags) {
          True -> element.none()
          False ->
            html.div(
              [attribute.class("flex flex-wrap gap-2 pt-2")],
              list.map(photo.tags, fn(tag) {
                html.span(
                  [
                    attribute.class(
                      "px-3 py-1 bg-surface-dim text-sm text-accent rounded-md border border-border-light",
                    ),
                  ],
                  [element.text(tag)],
                )
              }),
            )
        },
      ]),
      // Right: stats & info
      html.div(
        [
          attribute.class(
            "space-y-4 p-6 bg-surface-dim rounded-xl border border-border-light",
          ),
        ],
        [
          stat_row("👁", "Views", int.to_string(stats.views)),
          stat_row("❤️", "Likes", int.to_string(stats.likes)),
          stat_row("⬇", "Downloads", int.to_string(stats.downloads)),
          case photo.location {
            option.Some(loc) -> stat_row("📍", "Location", loc)
            option.None -> element.none()
          },
          case photo.camera {
            option.Some(cam) -> stat_row("📷", "Camera", cam)
            option.None -> element.none()
          },
        ],
      ),
    ]),
  ])
}

fn stat_row(icon: String, label: String, value: String) -> Element(msg) {
  html.div([attribute.class("flex items-center justify-between")], [
    html.span([attribute.class("flex items-center gap-2 text-sm text-accent")], [
      html.span([], [element.text(icon)]),
      element.text(label),
    ]),
    html.span([attribute.class("text-sm font-medium text-primary")], [
      element.text(value),
    ]),
  ])
}

fn photo_image_url(thumb: shared_thumbnail.Thumbnail) -> String {
  case thumb.premium {
    True -> "/" <> shared_routes.photo_data_premium <> thumb.asset_id
    False -> "/" <> shared_routes.photo_data <> thumb.asset_id
  }
}
