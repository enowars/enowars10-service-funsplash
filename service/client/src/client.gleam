import gleam/io
import lustre
import lustre/effect
import lustre/element
import router

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])
  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model
}

fn init(_) -> #(Model, effect.Effect(c)) {
  let model = Model
  #(model, effect.none())
}

// UPDATE ----------------------------------------------------------------------

fn update(value: a, value_2: b) -> #(a, effect.Effect(b)) {
  todo
}

// VIEW ------------------------------------------------------------------------
fn view(value: a) -> element.Element(b) {
  let styles = [
    #("max-width", "30ch"),
    #("margin", "0 auto"),
    #("display", "flex"),
    #("flex-direction", "column"),
    #("gap", "1em"),
  ]

  todo
}
