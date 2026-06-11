import formal/form.{type Form}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import youid/uuid.{type Uuid}

pub type Upload {
  Upload(
    creator: Uuid,
    data: BitArray,
    description: Option(String),
    premium: Bool,
    private: Bool,
    location: Option(String),
    camera: Option(String),
    show_on_profile: Bool,
    tags: List(String),
  )
}

pub fn upload_form(creator: Uuid, data: BitArray) -> Form(Upload) {
  form.new({
    use description <- form.field(
      "description",
      form.parse_optional(form.parse_string),
    )
    use premium <- form.field("premium", form.parse_checkbox)
    use private <- form.field("private", form.parse_checkbox)
    use location <- form.field(
      "location",
      form.parse_optional(form.parse_string),
    )
    use camera <- form.field("camera", form.parse_optional(form.parse_string))
    use show_on_profile <- form.field("show_on_profile", form.parse_checkbox)

    use tags <- form.field("tags", {
      form.parse_string
      |> form.map(fn(raw) {
        string.split(raw, ",")
        |> list.map(string.trim)
        |> list.filter(fn(s) { s != "" })
      })
    })

    form.success(Upload(
      creator:,
      data:,
      description:,
      premium:,
      private:,
      location:,
      camera:,
      show_on_profile:,
      tags:,
    ))
  })
}
