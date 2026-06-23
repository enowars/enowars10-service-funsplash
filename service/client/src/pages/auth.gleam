import formal/form
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/uri
import lustre/attribute.{class, name, type_}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{button, div, h1, input, label, p, small}
import shared/shared_login
import shared/shared_signup

// MODEL -----------------------------------------------------------------------

pub type Mode {
  LoginMode
  SignUpMode
}

pub type Model {
  Model(mode: Mode, error: Option(String), success: Option(String))
}

pub fn init(mode: Mode, query: Option(String)) -> #(Model, Effect(Message)) {
  let params = case query {
    Some(q) -> uri.parse_query(q) |> result.unwrap([])
    None -> []
  }
  let error = list.key_find(params, "error") |> option.from_result
  let success = list.key_find(params, "registered") |> option.from_result
  let error_msg = case error {
    Some("invalid_credentials") -> Some("Invalid username or password.")
    Some("invalid_data") ->
      Some("Could not create account. Username may be taken.")
    Some(_) -> Some("An error occurred.")
    None -> None
  }
  let success_msg = case success {
    Some("true") -> Some("Account created! Please log in.")
    _ -> None
  }
  #(Model(mode:, error: error_msg, success: success_msg), effect.none())
}

// UPDATE ----------------------------------------------------------------------

pub type Message

pub fn update(model: Model, _message: Message) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Message) {
  div([class("flex items-center justify-center min-h-[80vh] px-4")], [
    div([class("w-full max-w-sm")], [
      case model.mode {
        LoginMode -> login_view(model)
        SignUpMode -> signup_view(model)
      },
    ]),
  ])
}

fn login_view(model: Model) -> Element(Message) {
  let form = shared_login.form()
  div([], [
    h1([class("text-2xl font-bold text-center mb-1")], [text("Login")]),
    p([class("text-sm text-gray-500 text-center mb-6")], [
      text("Welcome back."),
    ]),
    success_banner(model.success),
    error_banner(model.error),
    html.form(
      [
        attribute.action("/napi/login"),
        attribute.method("POST"),
        class("space-y-4"),
      ],
      [
        field(form, "username", "Username", "text"),
        field(form, "password", "Password", "password"),
        button(
          [
            type_("submit"),
            class(
              "w-full rounded-md bg-black py-2.5 text-sm font-medium text-white hover:bg-gray-800",
            ),
          ],
          [text("Log in")],
        ),
        p([class("text-center text-sm text-gray-500 mt-4")], [
          text("Don't have an account? "),
          html.a([attribute.href("/join"), class("text-black underline")], [
            text("Join"),
          ]),
        ]),
      ],
    ),
  ])
}

fn signup_view(model: Model) -> Element(Message) {
  let form = shared_signup.form()
  div([], [
    h1([class("text-2xl font-bold text-center mb-1")], [text("Join funsplash")]),
    p([class("text-sm text-gray-500 text-center mb-6")], [
      text("Create your free account."),
    ]),
    error_banner(model.error),
    html.form(
      [
        attribute.action("/napi/join"),
        attribute.method("POST"),
        class("space-y-4"),
      ],
      [
        field(form, "username", "Username", "text"),
        field(form, "first_name", "First name", "text"),
        field(form, "last_name", "Last name (optional)", "text"),
        field(form, "bio", "Bio (optional)", "text"),
        field(form, "password", "Password", "password"),
        button(
          [
            type_("submit"),
            class(
              "w-full rounded-md bg-black py-2.5 text-sm font-medium text-white hover:bg-gray-800",
            ),
          ],
          [text("Join")],
        ),
        p([class("text-center text-sm text-gray-500 mt-4")], [
          text("Already have an account? "),
          html.a([attribute.href("/login"), class("text-black underline")], [
            text("Log in"),
          ]),
        ]),
      ],
    ),
  ])
}

fn field(
  form: form.Form(t),
  field_name: String,
  label_text: String,
  kind: String,
) -> Element(msg) {
  let errors = form.field_error_messages(form, field_name)
  div([], [
    label([class("block text-sm font-medium text-gray-700 mb-1")], [
      text(label_text),
    ]),
    input([
      type_(kind),
      name(field_name),
      attribute.default_value(form.field_value(form, field_name)),
      class(
        "w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-black focus:ring-1 focus:ring-black focus:outline-none",
      ),
      case errors {
        [] -> attribute.none()
        _ -> attribute.attribute("aria-invalid", "true")
      },
    ]),
    ..list.map(errors, fn(msg) {
      small([class("text-xs text-red-600")], [text(msg)])
    })
  ])
}

fn error_banner(error: Option(String)) -> Element(msg) {
  case error {
    Some(msg) ->
      div(
        [
          class(
            "rounded-md bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700 mb-4",
          ),
        ],
        [text(msg)],
      )
    None -> element.none()
  }
}

fn success_banner(success: Option(String)) -> Element(msg) {
  case success {
    Some(msg) ->
      div(
        [
          class(
            "rounded-md bg-green-50 border border-green-200 px-4 py-3 text-sm text-green-700 mb-4",
          ),
        ],
        [text(msg)],
      )
    None -> element.none()
  }
}

import gleam/result
