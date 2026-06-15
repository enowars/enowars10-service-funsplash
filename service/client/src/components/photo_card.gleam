import api/api_photo
import auth
import lustre/attribute.{alt, class, href, src}
import lustre/element.{type Element, text}
import lustre/element/html.{a, div, img}
import route
import shared/shared_privacy
import shared/shared_thumbnail.{type Thumbnail}

pub fn photo_card(thumb: Thumbnail, current_auth: auth.Auth) -> Element(msg) {
  div([class("group relative overflow-hidden rounded-lg bg-gray-100")], [
    a([href("/photos/" <> thumb.public_id), class("block h-full")], [
      img([
        src(api_photo.src_url(thumb, current_auth)),
        alt(case thumb.description {
          option.Some(d) -> d
          option.None -> "Photo by " <> thumb.creator
        }),
        class(
          "w-full h-full object-cover transition-transform duration-300 group-hover:scale-105",
        ),
      ]),
    ]),
    div(
      [
        class(
          "absolute top-2 right-2 flex flex-col gap-1 items-end pointer-events-none",
        ),
      ],
      [
        case thumb.privacy {
          shared_privacy.Premium ->
            div(
              [
                class(
                  "bg-yellow-500/90 text-white text-[10px] font-bold px-1.5 py-0.5 rounded shadow-sm backdrop-blur-sm",
                ),
              ],
              [text("PREMIUM")],
            )
          shared_privacy.Private ->
            div(
              [
                class(
                  "bg-red-500/90 text-white text-[10px] font-bold px-1.5 py-0.5 rounded shadow-sm backdrop-blur-sm",
                ),
              ],
              [text("PRIVATE")],
            )
          shared_privacy.Public -> element.none()
        },
        case thumb.show_on_profile {
          False ->
            div(
              [
                class(
                  "bg-gray-800/90 text-white text-[10px] font-bold px-1.5 py-0.5 rounded shadow-sm backdrop-blur-sm",
                ),
              ],
              [text("HIDDEN")],
            )
          True -> element.none()
        },
      ],
    ),
    div(
      [
        class(
          "absolute bottom-0 left-0 right-0 p-3 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity",
        ),
      ],
      [
        a(
          [
            route.href(route.User(thumb.creator)),
            class("text-sm text-white font-medium hover:underline"),
          ],
          [text(thumb.creator)],
        ),
        case thumb.description {
          option.Some(desc) ->
            html.p([class("text-xs text-white/80 mt-0.5 line-clamp-2")], [
              text(desc),
            ])
          option.None -> element.none()
        },
      ],
    ),
  ])
}

import gleam/option
