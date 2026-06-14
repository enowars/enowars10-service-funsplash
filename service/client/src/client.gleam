import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import modem
import router

// MAIN ------------------------------------------------------------------------

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(page: router.Page)
}

fn init(_) -> #(Model, Effect(router.Message)) {
  let #(page, effect) = router.init(modem.initial_uri())

  #(Model(page:), effect.batch([modem.init(router.on_url_change), effect]))
}

// UPDATE ----------------------------------------------------------------------

fn update(
  model: Model,
  message: router.Message,
) -> #(Model, Effect(router.Message)) {
  let #(page, effect) = router.update(model.page, message)
  #(Model(page:), effect)
}

// VIEW ------------------------------------------------------------------------
fn view(model: Model) -> Element(router.Message) {
  router.view(model.page)
}
