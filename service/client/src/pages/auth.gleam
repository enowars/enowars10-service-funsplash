import formal/form.{type Form}
import gleam/io
import gleam/list
import gleam/option.{None}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/shared_upload
import shared/shared_user

// MODEL -----------------------------------------------------------------------

pub type Model {
  User(user: shared_user.SignUpForm)
}

pub fn init() -> #(Model, Effect(Message)) {
  #(
    User(shared_user.SignUpForm(
      username: "",
      first_name: "",
      password: "",
      last_name: None,
      bio: None,
      available_for_hire: False,
    )),
    effect.none(),
  )
}

// UPDATE ----------------------------------------------------------------------

pub type Message {
  UserSubmittedSignupForm(
    result: Result(shared_user.SignUpForm, Form(shared_user.SignUpForm)),
  )
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    UserSubmittedSignupForm(result: Ok(signup)) -> todo
    UserSubmittedSignupForm(result: Error(form)) -> todo
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Message) {
  todo
}

fn signup_page_view(form: Form(shared_user.SignUpForm)) -> Element(Message) {
  let submitted = fn(fields) {
    form |> form.add_values(fields) |> form.run |> UserSubmittedSignupForm
  }
  html.form([attribute.method("POST"), event.on_submit(submitted)], [
    field_input(form, "username", kind: "text", label: "Username"),
    field_input(form, "first_name", kind: "text", label: "First Name"),
    field_input(form, "last_name", kind: "text", label: "Last Name (Optional)"),
    field_input(form, "bio", kind: "text", label: "Bio (Optional)"),
    field_input(form, "password", kind: "password", label: "Password"),
    field_input(form, "confirm", kind: "password", label: "Confirmation"),
    field_input(
      form,
      "available_for_hire",
      kind: "checkbox",
      label: "Available for Hire",
    ),
    html.div([], [html.input([attribute.type_("submit")])]),
  ])
}

fn field_input(
  form: Form(t),
  name name: String,
  kind kind: String,
  label label_text: String,
) -> Element(a) {
  let errors = form.field_error_messages(form, name)

  html.label([], [
    // The label text, for the user to read
    element.text(label_text),
    // The input, for the user to type into
    html.input([
      attribute.type_(kind),
      attribute.name(name),
      attribute.default_value(form.field_value(form, name)),
      case errors {
        [] -> attribute.none()
        _ -> attribute.aria_invalid("true")
      },
    ]),
    // Any errors presented below
    ..list.map(errors, fn(msg) { html.small([], [element.text(msg)]) })
  ])
}
