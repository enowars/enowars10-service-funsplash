import gleam/io
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model
}

pub fn init() -> #(Model, Effect(Message)) {
  #(Model, effect.none())
}

// UPDATE ----------------------------------------------------------------------

pub type Message

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  todo
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Message) {
  todo
}
