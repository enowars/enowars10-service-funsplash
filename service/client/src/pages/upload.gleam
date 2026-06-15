import gleam/list
import lustre/attribute.{class, name, type_, value}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{
  button, div, h1, input, label, option, select, textarea,
}
import shared/shared_privacy

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model
}

pub fn init() -> #(Model, Effect(Message)) {
  #(Model, effect.none())
}

// UPDATE ----------------------------------------------------------------------

pub type Message

pub fn update(model: Model, _message: Message) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

// VIEW ------------------------------------------------------------------------

pub fn view(_model: Model) -> Element(Message) {
  div([class("max-w-lg mx-auto py-12 px-4")], [
    h1([class("text-2xl font-bold mb-6")], [text("Upload a photo")]),
    html.form(
      [
        attribute.action("/napi/upload"),
        attribute.method("POST"),
        attribute.attribute("enctype", "multipart/form-data"),
        class("space-y-5"),
      ],
      [
        // Photo file
        div([], [
          label([class("block text-sm font-medium text-gray-700 mb-1")], [
            text("Photo"),
          ]),
          input([
            type_("file"),
            name("photo"),
            attribute.attribute("accept", "image/*"),
            attribute.attribute("required", ""),
            class(
              "block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-black file:text-white hover:file:bg-gray-800",
            ),
          ]),
        ]),
        // Description
        div([], [
          label([class("block text-sm font-medium text-gray-700 mb-1")], [
            text("Description (optional)"),
          ]),
          textarea(
            [
              name("description"),
              attribute.attribute("rows", "3"),
              class(
                "w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-black focus:ring-1 focus:ring-black focus:outline-none",
              ),
            ],
            "",
          ),
        ]),
        // Privacy
        div([], [
          label([class("block text-sm font-medium text-gray-700 mb-1")], [
            text("Privacy"),
          ]),
          privacy_select(),
        ]),
        // Location
        div([], [
          label([class("block text-sm font-medium text-gray-700 mb-1")], [
            text("Location (optional)"),
          ]),
          input([
            type_("text"),
            name("location"),
            class(
              "w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-black focus:ring-1 focus:ring-black focus:outline-none",
            ),
          ]),
        ]),
        // Camera
        div([], [
          label([class("block text-sm font-medium text-gray-700 mb-1")], [
            text("Camera (optional)"),
          ]),
          input([
            type_("text"),
            name("camera"),
            class(
              "w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-black focus:ring-1 focus:ring-black focus:outline-none",
            ),
          ]),
        ]),
        // Tags
        div([], [
          label([class("block text-sm font-medium text-gray-700 mb-1")], [
            text("Tags (optional, comma-separated)"),
          ]),
          input([
            type_("text"),
            name("tags"),
            class(
              "w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-black focus:ring-1 focus:ring-black focus:outline-none",
            ),
          ]),
        ]),
        // Show on profile
        div([class("flex items-center gap-2")], [
          input([
            type_("checkbox"),
            name("show_on_profile"),
            attribute.id("show_on_profile"),
            attribute.checked(True),
          ]),
          label(
            [attribute.for("show_on_profile"), class("text-sm text-gray-700")],
            [
              text("Show on profile"),
            ],
          ),
        ]),
        // Submit
        button(
          [
            type_("submit"),
            class(
              "w-full rounded-md bg-black py-2.5 text-sm font-medium text-white hover:bg-gray-800",
            ),
          ],
          [text("Upload")],
        ),
      ],
    ),
  ])
}

fn privacy_select() -> Element(msg) {
  let all_options = shared_privacy.to_list()
  let option_elements =
    list.map(all_options, fn(variant) {
      option(
        [
          value(shared_privacy.to_string(variant)),
          attribute.selected(variant == shared_privacy.Public),
        ],
        shared_privacy.to_string(variant),
      )
    })
  select(
    [
      name("privacy"),
      class(
        "w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-black focus:ring-1 focus:ring-black focus:outline-none",
      ),
    ],
    option_elements,
  )
}
