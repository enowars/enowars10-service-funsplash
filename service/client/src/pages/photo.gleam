import api/api_photo
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import rsvp
import shared/shared_photo

// MODEL -----------------------------------------------------------------------

pub type Model {
  Loading
  Loaded(photo: shared_photo.Photo)
  Error
}

pub fn init(id: Int) -> #(Model, Effect(Message)) {
  let effect = api_photo.fetch(id, ApiReturnedPhoto)
  #(Loading, effect)
}

// UPDATE ----------------------------------------------------------------------

pub type Message {
  ApiReturnedPhoto(Result(shared_photo.Photo, rsvp.Error(String)))
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    ApiReturnedPhoto(Ok(photo)) -> #(Loaded(photo), effect.none())
    ApiReturnedPhoto(_) -> #(Error, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Message) {
  html.div([attribute.class("page-enter")], [
    case model {
      Loading -> loading_view()
      Loaded(photo) -> photo_view(photo)
      Error -> error_view()
    },
  ])
}

fn error_view() -> Element(Message) {
  todo
}

fn photo_view(photo: shared_photo.Photo) -> Element(Message) {
  todo
}

fn loading_view() -> Element(Message) {
  todo
}
