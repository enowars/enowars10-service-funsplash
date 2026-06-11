import gleam/option.{type Option, None, Some}
import youid/uuid.{type Uuid}

pub type Upload {
  Upload(
    creator: String,
    description: Option(String),
    premium: Bool,
    private: Bool,
    location: Option(String),
    camera: Option(String),
    show_on_profile: Bool,
    data: BitArray,
    tags: List(String),
  )
}

pub fn default_upload(creator: String, data: BitArray) -> Upload {
  Upload(
    creator:,
    description: None,
    premium: False,
    private: False,
    location: None,
    camera: None,
    show_on_profile: True,
    data:,
    tags: [],
  )
}
