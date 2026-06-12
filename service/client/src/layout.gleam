import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router.{type Route}

// ---------------------------------------------------------------------------
// Navbar
// ---------------------------------------------------------------------------

pub fn navbar(route: Route, auth_user: Option(String)) -> Element(msg) {
  html.nav(
    [
      attribute.class(
        "sticky top-0 z-50 bg-white/90 backdrop-blur-md border-b border-border-light",
      ),
    ],
    [
      html.div(
        [
          attribute.class(
            "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between h-16",
          ),
        ],
        [nav_left(route), nav_center(), nav_right(route, auth_user)],
      ),
    ],
  )
}

fn nav_left(_route: Route) -> Element(msg) {
  html.div([attribute.class("flex items-center gap-6")], [
    html.a(
      [
        router.href(router.Index),
        attribute.class(
          "text-xl font-bold tracking-tight text-primary hover:text-primary-hover transition-colors",
        ),
      ],
      [
        html.span([attribute.class("text-2xl mr-1")], [element.text("📸")]),
        element.text("funsplash"),
      ],
    ),
  ])
}

fn nav_center() -> Element(msg) {
  html.div([attribute.class("hidden md:flex flex-1 max-w-xl mx-8")], [
    html.div(
      [
        attribute.class(
          "relative w-full flex items-center bg-surface-dim rounded-full border border-border-light",
        ),
      ],
      [
        html.span([attribute.class("absolute left-4 text-accent text-sm")], [
          element.text("🔍"),
        ]),
        html.input([
          attribute.type_("text"),
          attribute.placeholder("Search photos"),
          attribute.class(
            "w-full py-2.5 pl-11 pr-4 bg-transparent text-sm text-primary placeholder-accent rounded-full",
          ),
          attribute.attribute("readonly", "true"),
        ]),
      ],
    ),
  ])
}

fn nav_right(route: Route, auth_user: Option(String)) -> Element(msg) {
  html.div([attribute.class("flex items-center gap-3")], [
    nav_link("Explore", router.Index, route),
    // Upload button
    html.a(
      [
        router.href(router.Upload),
        attribute.class(
          "hidden sm:inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-accent hover:text-primary transition-colors",
        ),
      ],
      [
        html.span([attribute.class("text-base")], [element.text("⬆")]),
        element.text("Upload"),
      ],
    ),
    // Divider
    html.div([attribute.class("hidden sm:block w-px h-8 bg-border-light")], []),
    // Auth section — conditional on login state
    case auth_user {
      Some(username) -> logged_in_nav(username)
      None -> logged_out_nav()
    },
  ])
}

fn logged_in_nav(username: String) -> Element(msg) {
  html.div([attribute.class("flex items-center gap-3")], [
    // Profile link
    html.a(
      [
        router.href(router.UserByName(username)),
        attribute.class(
          "flex items-center gap-2 px-3 py-2 text-sm font-medium text-primary hover:bg-surface-dim rounded-lg transition-colors",
        ),
      ],
      [
        html.div(
          [
            attribute.class(
              "w-7 h-7 rounded-full bg-gray-200 flex items-center justify-center text-xs font-bold text-accent",
            ),
          ],
          [element.text("👤")],
        ),
        html.span([attribute.class("hidden sm:inline")], [
          element.text(username),
        ]),
      ],
    ),
    // Logout
    html.a(
      [
        attribute.href("/logout"),
        attribute.class(
          "px-4 py-2 text-sm font-medium text-accent hover:text-primary transition-colors",
        ),
      ],
      [element.text("Log out")],
    ),
  ])
}

fn logged_out_nav() -> Element(msg) {
  html.div([attribute.class("flex items-center gap-3")], [
    html.a(
      [
        router.href(router.Login),
        attribute.class(
          "px-4 py-2 text-sm font-medium text-accent hover:text-primary transition-colors",
        ),
      ],
      [element.text("Log in")],
    ),
    html.a(
      [
        router.href(router.Join),
        attribute.class(
          "px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-hover rounded-md transition-colors",
        ),
      ],
      [element.text("Join")],
    ),
  ])
}

fn nav_link(label: String, target: Route, current: Route) -> Element(msg) {
  let active_class = case target == current {
    True -> " text-primary font-semibold"
    False -> " text-accent hover:text-primary"
  }
  html.a(
    [
      router.href(target),
      attribute.class(
        "hidden lg:inline-block px-3 py-2 text-sm transition-colors" <> active_class,
      ),
    ],
    [element.text(label)],
  )
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

pub fn footer() -> Element(msg) {
  html.footer(
    [attribute.class("border-t border-border-light bg-surface-dim mt-auto")],
    [
      html.div(
        [
          attribute.class(
            "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 grid grid-cols-1 sm:grid-cols-3 gap-8",
          ),
        ],
        [
          html.div([], [
            html.h3([attribute.class("font-bold text-primary text-lg mb-2")], [
              element.text("📸 funsplash"),
            ]),
            html.p([attribute.class("text-sm text-accent leading-relaxed")], [
              element.text(
                "The internet's source of freely-usable images. Powered by creators everywhere.",
              ),
            ]),
          ]),
          html.div([], [
            html.h4(
              [attribute.class("font-semibold text-primary text-sm mb-3")],
              [element.text("Product")],
            ),
            footer_links([
              #("Explore", router.Index),
              #("Upload", router.Upload),
            ]),
          ]),
          html.div([], [
            html.h4(
              [attribute.class("font-semibold text-primary text-sm mb-3")],
              [element.text("Account")],
            ),
            footer_links([
              #("Log in", router.Login),
              #("Join", router.Join),
            ]),
          ]),
        ],
      ),
      html.div(
        [attribute.class("border-t border-border-light")],
        [
          html.div(
            [
              attribute.class(
                "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 text-xs text-accent",
              ),
            ],
            [element.text("© 2026 funsplash")],
          ),
        ],
      ),
    ],
  )
}

fn footer_links(links: List(#(String, Route))) -> Element(msg) {
  html.ul(
    [attribute.class("space-y-2")],
    list.map(links, fn(link) {
      let #(label, route) = link
      html.li([], [
        html.a(
          [
            router.href(route),
            attribute.class(
              "text-sm text-accent hover:text-primary transition-colors",
            ),
          ],
          [element.text(label)],
        ),
      ])
    }),
  )
}
