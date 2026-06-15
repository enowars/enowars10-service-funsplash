import api/api_photo
import auth.{type Auth}
import browser
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{a, button, div, nav}
import lustre/event
import route
import rsvp

pub type Message {
  UserClickedLogout
  LogoutCompleted(Result(String, rsvp.Error(String)))
}

pub fn update(message: Message) -> Effect(Message) {
  case message {
    UserClickedLogout -> {
      let url = api_photo.api_base_url() <> "/logout"
      let handler = rsvp.expect_text(LogoutCompleted)
      rsvp.get(url, handler)
    }
    LogoutCompleted(_) -> {
      effect.from(fn(_) { browser.navigate_to("/") })
    }
  }
}

pub fn navbar(auth: Auth) -> Element(Message) {
  nav(
    [
      class(
        "flex items-center justify-between px-5 py-3 border-b border-gray-200 bg-white",
      ),
    ],
    [
      a(
        [
          attribute.href("/"),
          class("text-xl font-bold tracking-tight text-black"),
        ],
        [
          text("funsplash"),
        ],
      ),
      div([class("flex items-center gap-4")], case auth {
        auth.LoggedIn(user) -> [
          a(
            [
              route.href(route.Upload),
              class("text-sm text-gray-600 hover:text-black"),
            ],
            [text("Upload")],
          ),
          a(
            [
              route.href(route.User(user.username)),
              class("text-sm text-gray-600 hover:text-black"),
            ],
            [text("@" <> user.username)],
          ),
          button(
            [
              event.on_click(UserClickedLogout),
              class("text-sm text-gray-500 hover:text-black cursor-pointer"),
            ],
            [text("Log out")],
          ),
        ]
        _ -> [
          a(
            [
              route.href(route.Login),
              class("text-sm text-gray-600 hover:text-black"),
            ],
            [text("Log in")],
          ),
          a(
            [
              route.href(route.Join),
              class(
                "rounded-md bg-black px-4 py-1.5 text-sm text-white hover:bg-gray-800",
              ),
            ],
            [text("Join")],
          ),
        ]
      }),
    ],
  )
}
