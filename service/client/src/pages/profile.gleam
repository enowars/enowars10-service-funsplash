import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router
import shared/shared_routes
import shared/shared_thumbnail
import shared/shared_user

pub type Model {
  NotLoaded
  Loading
  Loaded(shared_user.User)
  Error
}

pub fn view(model: Model, auth_user: Option(String)) -> Element(msg) {
  html.div([attribute.class("page-enter")], [
    case model {
      NotLoaded | Loading -> loading_view()
      Loaded(user) -> profile_view(user, auth_user)
      Error -> error_view()
    },
  ])
}

fn loading_view() -> Element(msg) {
  html.div(
    [attribute.class("max-w-5xl mx-auto px-4 py-12 animate-pulse-soft")],
    [
      html.div([attribute.class("flex items-center gap-6 mb-12")], [
        html.div([attribute.class("skeleton w-24 h-24 rounded-full")], []),
        html.div([attribute.class("space-y-3")], [
          html.div([attribute.class("skeleton w-48 h-6")], []),
          html.div([attribute.class("skeleton w-32 h-4")], []),
        ]),
      ]),
      html.div([attribute.class("grid grid-cols-3 gap-4")], [
        html.div([attribute.class("skeleton h-48")], []),
        html.div([attribute.class("skeleton h-56")], []),
        html.div([attribute.class("skeleton h-44")], []),
      ]),
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
      html.div([attribute.class("text-6xl mb-6")], [element.text("👤")]),
      html.h1(
        [attribute.class("text-2xl font-bold text-primary mb-3")],
        [element.text("User not found")],
      ),
      html.p([attribute.class("text-accent mb-8")], [
        element.text("This profile doesn't exist or has been removed."),
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

fn profile_view(
  user: shared_user.User,
  auth_user: Option(String),
) -> Element(msg) {
  let display_name = case user.last_name {
    Some(last) -> user.first_name <> " " <> last
    None -> user.first_name
  }

  let is_own = auth_user == Some(user.username)

  html.div([attribute.class("animate-fade-in")], [
    // Profile header
    html.div([attribute.class("bg-surface-dim border-b border-border-light")], [
      html.div(
        [
          attribute.class(
            "max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-12 flex flex-col sm:flex-row items-center sm:items-start gap-6",
          ),
        ],
        [
          // Avatar
          html.div(
            [
              attribute.class(
                "w-28 h-28 rounded-full bg-gray-200 flex items-center justify-center text-5xl flex-shrink-0 ring-4 ring-white shadow-lg",
              ),
            ],
            [element.text("👤")],
          ),
          // Info
          html.div(
            [attribute.class("text-center sm:text-left flex-1")],
            [
              html.div(
                [
                  attribute.class(
                    "flex items-center gap-3 mb-1 justify-center sm:justify-start flex-wrap",
                  ),
                ],
                [
                  html.h1(
                    [attribute.class("text-2xl font-bold text-primary")],
                    [element.text(display_name)],
                  ),
                  case user.premium {
                    True ->
                      html.span(
                        [
                          attribute.class(
                            "px-2 py-0.5 text-xs font-bold text-premium bg-premium/10 rounded-full",
                          ),
                        ],
                        [element.text("★ PREMIUM")],
                      )
                    False -> element.none()
                  },
                  case user.available_for_hire {
                    True ->
                      html.span(
                        [
                          attribute.class(
                            "px-2 py-0.5 text-xs font-medium text-green-700 bg-green-100 rounded-full",
                          ),
                        ],
                        [element.text("Available for hire")],
                      )
                    False -> element.none()
                  },
                  case is_own {
                    True ->
                      html.span(
                        [
                          attribute.class(
                            "px-2 py-0.5 text-xs font-medium text-blue-700 bg-blue-100 rounded-full",
                          ),
                        ],
                        [element.text("You")],
                      )
                    False -> element.none()
                  },
                ],
              ),
              html.p([attribute.class("text-sm text-accent mb-3")], [
                element.text("@" <> user.username),
              ]),
              case user.bio {
                Some(bio) ->
                  html.p(
                    [
                      attribute.class(
                        "text-sm text-accent leading-relaxed max-w-lg",
                      ),
                    ],
                    [element.text(bio)],
                  )
                None -> element.none()
              },
              // Stats row
              html.div(
                [attribute.class("flex items-center gap-6 mt-4 justify-center sm:justify-start")],
                [
                  html.div([], [
                    html.span(
                      [attribute.class("font-semibold text-primary")],
                      [
                        element.text(
                          list.length(user.photos) |> int.to_string,
                        ),
                      ],
                    ),
                    html.span([attribute.class("text-sm text-accent ml-1")], [
                      element.text("photos"),
                    ]),
                  ]),
                ],
              ),
              // Own-profile action buttons
              case is_own {
                True ->
                  html.div(
                    [attribute.class("flex items-center gap-3 mt-5 justify-center sm:justify-start")],
                    [
                      html.a(
                        [
                          router.href(router.Upload),
                          attribute.class(
                            "inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-white text-sm font-medium rounded-lg hover:bg-primary-hover transition-colors",
                          ),
                        ],
                        [
                          html.span([], [element.text("⬆")]),
                          element.text("Upload a photo"),
                        ],
                      ),
                      html.a(
                        [
                          attribute.href("/logout"),
                          attribute.class(
                            "inline-flex items-center gap-2 px-5 py-2.5 border border-border text-sm font-medium text-accent rounded-lg hover:text-primary hover:border-primary transition-colors",
                          ),
                        ],
                        [element.text("Log out")],
                      ),
                    ],
                  )
                False -> element.none()
              },
            ],
          ),
        ],
      ),
    ]),
    // Photo grid
    html.div(
      [attribute.class("max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10")],
      [
        case is_own {
          True ->
            html.div(
              [attribute.class("flex items-center justify-between mb-6")],
              [
                html.h2(
                  [attribute.class("text-lg font-semibold text-primary")],
                  [element.text("Your photos")],
                ),
                html.a(
                  [
                    router.href(router.Upload),
                    attribute.class(
                      "text-sm text-accent hover:text-primary transition-colors",
                    ),
                  ],
                  [element.text("+ Upload new")],
                ),
              ],
            )
          False ->
            html.h2(
              [attribute.class("text-lg font-semibold text-primary mb-6")],
              [element.text("Photos")],
            )
        },
        case list.is_empty(user.photos) {
          True -> empty_photos(is_own)
          False -> photo_grid(user.photos)
        },
      ],
    ),
  ])
}

fn photo_grid(photos: List(shared_thumbnail.Thumbnail)) -> Element(msg) {
  html.div(
    [attribute.class("photo-grid")],
    list.map(photos, photo_card),
  )
}

fn photo_card(thumb: shared_thumbnail.Thumbnail) -> Element(msg) {
  let image_url = case thumb.premium {
    True -> "/" <> shared_routes.photo_data_premium <> thumb.asset_id
    False -> "/" <> shared_routes.photo_data <> thumb.asset_id
  }

  html.a(
    [
      attribute.href("/photos/" <> thumb.public_id),
      attribute.class("photo-card block"),
    ],
    [
      html.img([
        attribute.src(image_url),
        attribute.alt(
          thumb.description |> option.unwrap("Photo by " <> thumb.creator),
        ),
        attribute.class("w-full rounded-lg"),
        attribute.attribute("loading", "lazy"),
      ]),
      html.div([attribute.class("photo-overlay")], [
        html.div(
          [attribute.class("w-full flex items-center justify-between")],
          [
            html.span([attribute.class("text-white text-sm font-medium")], [
              element.text(thumb.creator),
            ]),
            html.div([attribute.class("flex items-center gap-2")], [
              case thumb.premium {
                True ->
                  html.span(
                    [attribute.class("text-premium text-xs font-bold")],
                    [element.text("★")],
                  )
                False -> element.none()
              },
              case thumb.private {
                True ->
                  html.span(
                    [attribute.class("text-white/70 text-xs")],
                    [element.text("🔒")],
                  )
                False -> element.none()
              },
              case thumb.user_liked {
                True ->
                  html.span([attribute.class("text-red-400")], [
                    element.text("❤️"),
                  ])
                False -> element.none()
              },
            ]),
          ],
        ),
      ]),
    ],
  )
}

fn empty_photos(is_own: Bool) -> Element(msg) {
  html.div([attribute.class("text-center py-20")], [
    html.div([attribute.class("text-5xl mb-4")], [element.text("📷")]),
    html.p([attribute.class("text-lg text-accent mb-4")], [
      element.text(case is_own {
        True -> "You haven't uploaded any photos yet"
        False -> "No photos yet"
      }),
    ]),
    case is_own {
      True ->
        html.a(
          [
            router.href(router.Upload),
            attribute.class(
              "inline-block px-6 py-2.5 bg-primary text-white rounded-lg hover:bg-primary-hover transition-colors text-sm font-medium",
            ),
          ],
          [element.text("Upload your first photo →")],
        )
      False -> element.none()
    },
  ])
}
