import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(error: Option(String)) -> Element(msg) {
  let alert = case error {
    Some(err) -> alert_banner(err)
    None -> element.none()
  }

  html.div(
    [
      attribute.class(
        "min-h-[calc(100vh-12rem)] flex items-center justify-center px-4 py-16 bg-surface-dim",
      ),
    ],
    [
      html.div(
        [
          attribute.class(
            "w-full max-w-2xl glass-card rounded-2xl p-8 animate-fade-in",
          ),
        ],
        [
          html.div([attribute.class("text-center mb-8")], [
            html.div([attribute.class("text-4xl mb-4")], [
              element.text("⬆️"),
            ]),
            html.h1(
              [attribute.class("text-2xl font-bold text-primary mb-2")],
              [element.text("Upload a photo")],
            ),
            html.p([attribute.class("text-sm text-accent")], [
              element.text("Share your best work with the community."),
            ]),
          ]),
          html.div([attribute.class("space-y-4")], [
            alert,
            html.form(
              [
                attribute.method("POST"),
                attribute.action("/upload"),
                attribute.attribute("enctype", "multipart/form-data"),
                attribute.class("space-y-5"),
              ],
              [
                // Photo file input
                html.div([], [
                  html.label(
                    [
                      attribute.for("photo"),
                      attribute.class(
                        "block text-sm font-medium text-primary mb-1.5",
                      ),
                    ],
                    [element.text("Photo *")],
                  ),
                  html.input([
                    attribute.type_("file"),
                    attribute.name("photo"),
                    attribute.id("photo"),
                    attribute.accept(["image/png", "image/jpeg", "image/webp"]),
                    attribute.attribute("required", "true"),
                    attribute.class(
                      "w-full px-4 py-3 border border-border rounded-lg text-sm text-primary bg-white file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-primary file:text-white hover:file:bg-primary-hover file:cursor-pointer file:transition-colors",
                    ),
                  ]),
                ]),
                // Description
                html.div([], [
                  html.label(
                    [
                      attribute.for("description"),
                      attribute.class(
                        "block text-sm font-medium text-primary mb-1.5",
                      ),
                    ],
                    [element.text("Description")],
                  ),
                  html.textarea(
                    [
                      attribute.name("description"),
                      attribute.id("description"),
                      attribute.placeholder(
                        "Describe your photo (optional)",
                      ),
                      attribute.class(
                        "w-full px-4 py-3 border border-border rounded-lg text-sm text-primary placeholder-accent bg-white transition-all",
                      ),
                      attribute.attribute("rows", "3"),
                    ],
                    "",
                  ),
                ]),
                // Location and Camera in a row
                html.div([attribute.class("grid grid-cols-1 sm:grid-cols-2 gap-4")], [
                  field("location", "Location", "text", "Where was this taken?"),
                  field("camera", "Camera", "text", "Camera model"),
                ]),
                // Tags
                html.div([], [
                  html.label(
                    [
                      attribute.for("tags"),
                      attribute.class(
                        "block text-sm font-medium text-primary mb-1.5",
                      ),
                    ],
                    [element.text("Tags")],
                  ),
                  html.input([
                    attribute.type_("text"),
                    attribute.name("tags"),
                    attribute.id("tags"),
                    attribute.placeholder("nature, landscape, sunset"),
                    attribute.class(
                      "w-full px-4 py-3 border border-border rounded-lg text-sm text-primary placeholder-accent bg-white transition-all",
                    ),
                  ]),
                  html.p([attribute.class("text-xs text-accent mt-1")], [
                    element.text("Separate tags with commas"),
                  ]),
                ]),
                // Checkboxes
                html.div(
                  [attribute.class("space-y-3 pt-2")],
                  [
                    checkbox("show_on_profile", "Show on my profile", True),
                    checkbox("premium", "Premium content", False),
                    checkbox("private", "Private photo", False),
                  ],
                ),
                // Submit
                html.button(
                  [
                    attribute.type_("submit"),
                    attribute.class(
                      "w-full py-3 px-4 bg-primary text-white font-medium rounded-lg hover:bg-primary-hover transition-colors text-sm",
                    ),
                  ],
                  [element.text("Upload photo")],
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  )
}

fn field(
  name: String,
  label: String,
  type_: String,
  placeholder: String,
) -> Element(msg) {
  html.div([], [
    html.label(
      [
        attribute.for(name),
        attribute.class("block text-sm font-medium text-primary mb-1.5"),
      ],
      [element.text(label)],
    ),
    html.input([
      attribute.type_(type_),
      attribute.name(name),
      attribute.id(name),
      attribute.placeholder(placeholder),
      attribute.class(
        "w-full px-4 py-3 border border-border rounded-lg text-sm text-primary placeholder-accent bg-white transition-all",
      ),
    ]),
  ])
}

fn checkbox(
  name: String,
  label: String,
  checked: Bool,
) -> Element(msg) {
  html.div([attribute.class("flex items-center gap-3")], [
    html.input([
      attribute.type_("checkbox"),
      attribute.name(name),
      attribute.id(name),
      attribute.value("on"),
      attribute.checked(checked),
      attribute.class("w-4 h-4 rounded border-border text-primary"),
    ]),
    html.label(
      [
        attribute.for(name),
        attribute.class("text-sm text-accent"),
      ],
      [element.text(label)],
    ),
  ])
}

fn alert_banner(message: String) -> Element(msg) {
  html.div(
    [
      attribute.class(
        "p-4 rounded-lg border text-sm animate-fade-in bg-red-50 text-red-800 border-red-200",
      ),
    ],
    [element.text(message)],
  )
}
