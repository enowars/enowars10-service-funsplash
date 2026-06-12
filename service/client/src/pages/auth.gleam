import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn login_view(error: Option(String), success: Option(String)) -> Element(msg) {
  let alert = case error, success {
    Some(err), _ -> alert_banner(err, True)
    _, Some(succ) -> alert_banner(succ, False)
    None, None -> element.none()
  }

  auth_shell("Welcome back", "Log in to your account", [
    html.div([attribute.class("space-y-4")], [
      alert,
      html.form(
        [
          attribute.method("POST"),
          attribute.action("/login"),
          attribute.class("space-y-5"),
        ],
        [
          form_field("username", "Username", "text", "Enter your username", True),
          form_field("password", "Password", "password", "Enter your password", True),
          submit_button("Log in"),
          html.p(
            [attribute.class("text-center text-sm text-accent mt-4")],
            [
              element.text("Don't have an account? "),
              html.a(
                [
                  router.href(router.Join),
                  attribute.class(
                    "font-medium text-primary hover:underline",
                  ),
                ],
                [element.text("Join funsplash")],
              ),
            ],
          ),
        ],
      ),
    ]),
  ])
}

pub fn signup_view(error: Option(String)) -> Element(msg) {
  let alert = case error {
    Some(err) -> alert_banner(err, True)
    None -> element.none()
  }

  auth_shell("Join funsplash", "Create your free account", [
    html.div([attribute.class("space-y-4")], [
      alert,
      html.form(
        [
          attribute.method("POST"),
          attribute.action("/join"),
          attribute.class("space-y-5"),
        ],
        [
          form_field("username", "Username", "text", "Choose a username", True),
          form_field(
            "password",
            "Password",
            "password",
            "At least 9 characters",
            True,
          ),
          form_field(
            "first_name",
            "First name",
            "text",
            "Your first name",
            True,
          ),
          form_field(
            "last_name",
            "Last name",
            "text",
            "Your last name (optional)",
            False,
          ),
          // Bio
          html.div([], [
            html.label(
              [
                attribute.for("bio"),
                attribute.class("block text-sm font-medium text-primary mb-1.5"),
              ],
              [element.text("Bio")],
            ),
            html.textarea(
              [
                attribute.name("bio"),
                attribute.id("bio"),
                attribute.placeholder("Tell us about yourself (optional)"),
                attribute.class(
                  "w-full px-4 py-3 border border-border rounded-lg text-sm text-primary placeholder-accent bg-white transition-all",
                ),
                attribute.attribute("rows", "3"),
              ],
              "",
            ),
          ]),
          // Available for hire checkbox
          html.div([attribute.class("flex items-center gap-3")], [
            html.input([
              attribute.type_("checkbox"),
              attribute.name("available_for_hire"),
              attribute.id("available_for_hire"),
              attribute.value("on"),
              attribute.class(
                "w-4 h-4 rounded border-border text-primary",
              ),
            ]),
            html.label(
              [
                attribute.for("available_for_hire"),
                attribute.class("text-sm text-accent"),
              ],
              [element.text("Available for hire")],
            ),
          ]),
          submit_button("Create account"),
          html.p(
            [attribute.class("text-center text-sm text-accent mt-4")],
            [
              element.text("Already have an account? "),
              html.a(
                [
                  router.href(router.Login),
                  attribute.class(
                    "font-medium text-primary hover:underline",
                  ),
                ],
                [element.text("Log in")],
              ),
            ],
          ),
        ],
      ),
    ]),
  ])
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn auth_shell(
  title: String,
  subtitle: String,
  children: List(Element(msg)),
) -> Element(msg) {
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
            "w-full max-w-md glass-card rounded-2xl p-8 animate-fade-in",
          ),
        ],
        [
          html.div([attribute.class("text-center mb-8")], [
            html.div([attribute.class("text-4xl mb-4")], [
              element.text("📸"),
            ]),
            html.h1(
              [attribute.class("text-2xl font-bold text-primary mb-2")],
              [element.text(title)],
            ),
            html.p([attribute.class("text-sm text-accent")], [
              element.text(subtitle),
            ]),
          ]),
          ..children
        ],
      ),
    ],
  )
}

fn form_field(
  name: String,
  label: String,
  type_: String,
  placeholder: String,
  required: Bool,
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
      attribute.attribute("required", case required {
        True -> "true"
        False -> "false"
      }),
      attribute.class(
        "w-full px-4 py-3 border border-border rounded-lg text-sm text-primary placeholder-accent bg-white transition-all",
      ),
    ]),
  ])
}

fn submit_button(label: String) -> Element(msg) {
  html.button(
    [
      attribute.type_("submit"),
      attribute.class(
        "w-full py-3 px-4 bg-primary text-white font-medium rounded-lg hover:bg-primary-hover transition-colors text-sm",
      ),
    ],
    [element.text(label)],
  )
}

fn alert_banner(message: String, is_error: Bool) -> Element(msg) {
  let bg_color = case is_error {
    True -> "bg-red-50 text-red-800 border-red-200"
    False -> "bg-green-50 text-green-800 border-green-200"
  }
  html.div(
    [
      attribute.class(
        "p-4 rounded-lg border text-sm animate-fade-in " <> bg_color,
      ),
    ],
    [element.text(message)],
  )
}
