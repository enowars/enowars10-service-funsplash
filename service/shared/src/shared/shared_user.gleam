import formal/form.{type Form}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import shared/shared_thumbnail

pub type User {
  User(
    username: String,
    first_name: String,
    last_name: Option(String),
    bio: Option(String),
    available_for_hire: Bool,
    premium: Bool,
    photos: List(shared_thumbnail.Thumbnail),
  )
}

pub type LoginForm {
  LoginForm(username: String, password: String)
}

pub fn login_form() -> Form(LoginForm) {
  form.new({
    use username <- form.field("username", form.parse_string)
    use password <- form.field("password", form.parse_string)
    form.success(LoginForm(username:, password:))
  })
}

pub type SignUpForm {
  SignUpForm(
    username: String,
    password: String,
    first_name: String,
    last_name: Option(String),
    bio: Option(String),
    available_for_hire: Bool,
  )
}

pub fn signup_form() -> Form(SignUpForm) {
  form.new({
    use username <- form.field("username", form.parse_string)
    use password <- form.field(
      "password",
      form.parse_string |> form.check_string_length_more_than(8),
    )
    use first_name <- form.field("first_name", form.parse_string)
    use last_name <- form.field(
      "last_name",
      form.parse_string |> form.parse_optional,
    )
    use bio <- form.field("bio", form.parse_string |> form.parse_optional)
    use available_for_hire <- form.field(
      "available_for_hire",
      form.parse_checkbox,
    )
    form.success(SignUpForm(
      username:,
      password:,
      first_name:,
      last_name:,
      bio:,
      available_for_hire:,
    ))
  })
}

pub fn user_to_json(user: User) -> json.Json {
  let User(
    username:,
    first_name:,
    last_name:,
    bio:,
    available_for_hire:,
    premium:,
    photos:,
  ) = user
  json.object([
    #("username", json.string(username)),
    #("first_name", json.string(first_name)),
    #("last_name", case last_name {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("bio", case bio {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("available_for_hire", json.bool(available_for_hire)),
    #("premium", json.bool(premium)),
    #("photos", json.array(photos, shared_thumbnail.thumbnail_to_json)),
  ])
}

pub fn user_decoder() -> decode.Decoder(User) {
  use username <- decode.field("username", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use bio <- decode.field("bio", decode.optional(decode.string))
  use available_for_hire <- decode.field("available_for_hire", decode.bool)
  use premium <- decode.field("premium", decode.bool)
  use photos <- decode.field(
    "photos",
    decode.list(shared_thumbnail.thumbnail_decoder()),
  )
  decode.success(User(
    username:,
    first_name:,
    last_name:,
    bio:,
    available_for_hire:,
    premium:,
    photos:,
  ))
}
