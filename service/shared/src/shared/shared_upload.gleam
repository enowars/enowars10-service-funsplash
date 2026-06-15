import formal/form.{type Form}
import gleam/option.{type Option}
import shared/shared_privacy.{type Privacy}
import youid/uuid.{type Uuid}

pub type Upload {
  Upload(
    creator: Uuid,
    data: BitArray,
    description: Option(String),
    privacy: Privacy,
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
    use privacy_str <- form.field("privacy", form.parse_string)
    let privacy = shared_privacy.from_string(privacy_str)
    use location <- form.field(
      "location",
      form.parse_optional(form.parse_string),
    )
    use camera <- form.field("camera", form.parse_optional(form.parse_string))
    use show_on_profile <- form.field("show_on_profile", form.parse_checkbox)

    use tags <- form.field("tags", form.parse_list(form.parse_string))

    form.success(Upload(
      creator:,
      data:,
      description:,
      privacy:,
      location:,
      camera:,
      show_on_profile:,
      tags:,
    ))
  })
}
