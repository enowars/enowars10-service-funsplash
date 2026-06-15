import api/api_user
import auth
import components/photo_card
import gleam/list
import gleam/option
import gleam/string
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h1, p, span}
import rsvp
import shared/shared_user

// MODEL -----------------------------------------------------------------------

pub type Model {
  Loading(username: String)
  Loaded(user: shared_user.User)
  Failed
}

pub fn init(username: String) -> #(Model, Effect(Message)) {
  #(Loading(username), api_user.fetch(username, ApiReturnedUser))
}

// UPDATE ----------------------------------------------------------------------

pub type Message {
  ApiReturnedUser(Result(shared_user.User, rsvp.Error(String)))
}

pub fn update(_model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    ApiReturnedUser(Ok(user)) -> #(Loaded(user), effect.none())
    ApiReturnedUser(_) -> #(Failed, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model, current_auth: auth.Auth) -> Element(Message) {
  div([class("max-w-5xl mx-auto py-8 px-4")], [
    case model {
      Loading(username) ->
        p([class("text-center text-gray-400 text-sm py-20")], [
          text("Loading @" <> username <> "…"),
        ])
      Loaded(user) -> profile_view(user, current_auth)
      Failed ->
        p([class("text-center text-red-500 text-sm py-20")], [
          text("User not found."),
        ])
    },
  ])
}

fn profile_view(
  user: shared_user.User,
  current_auth: auth.Auth,
) -> Element(Message) {
  div([class("space-y-8")], [
    // Profile header
    div([class("flex flex-col items-center text-center space-y-2")], [
      div(
        [
          class(
            "w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center text-2xl font-bold text-gray-500",
          ),
        ],
        [text(string.slice(user.first_name, 0, 1))],
      ),
      h1([class("text-xl font-bold text-gray-900")], [text(user.first_name)]),
      p([class("text-sm text-gray-500")], [text("@" <> user.username)]),
      case user.bio {
        option.Some(bio) ->
          p([class("text-sm text-gray-600 max-w-md")], [text(bio)])
        option.None -> element.none()
      },
      case user.available_for_hire {
        True ->
          span(
            [
              class(
                "inline-block rounded-full bg-green-50 border border-green-200 px-3 py-0.5 text-xs text-green-700",
              ),
            ],
            [text("Available for hire")],
          )
        False -> element.none()
      },
    ]),
    // Photo grid
    case user.photos {
      [] ->
        p([class("text-center text-gray-400 text-sm py-8")], [
          text("No photos yet."),
        ])
      photos ->
        div(
          [class("grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4")],
          list.map(photos, fn(p) { photo_card.photo_card(p, current_auth) }),
        )
    },
  ])
}
