import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(success: Option(String)) -> Element(msg) {
  let success_banner = case success {
    Some(msg) ->
      html.div(
        [
          attribute.class(
            "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-6 animate-fade-in",
          ),
        ],
        [
          html.div(
            [
              attribute.class(
                "p-4 bg-green-50 text-green-800 border border-green-200 rounded-lg text-sm font-medium",
              ),
            ],
            [element.text(msg)],
          ),
        ],
      )
    None -> element.none()
  }

  html.div([], [
    success_banner,
    // Hero section
    html.section(
      [
        attribute.class(
          "hero-bg min-h-[540px] flex items-center justify-center px-4",
        ),
      ],
      [
        html.div(
          [
            attribute.class(
              "relative z-10 text-center max-w-3xl mx-auto animate-fade-in",
            ),
          ],
          [
            html.h1(
              [
                attribute.class(
                  "text-4xl sm:text-5xl md:text-6xl font-bold text-white mb-6 leading-tight",
                ),
              ],
              [element.text("funsplash")],
            ),
            html.p(
              [
                attribute.class(
                  "text-lg sm:text-xl md:text-2xl text-gray-200 mb-4",
                ),
              ],
              [
                element.text(
                  "The internet's source of freely-usable images.",
                ),
              ],
            ),
            html.p([attribute.class("text-sm text-gray-400 mb-10")], [
              element.text("Powered by creators everywhere."),
            ]),
            // Search bar
            html.div([attribute.class("max-w-2xl mx-auto animate-slide-up")], [
              html.div(
                [
                  attribute.class(
                    "flex items-center bg-white rounded-2xl overflow-hidden shadow-2xl",
                  ),
                ],
                [
                  html.span([attribute.class("pl-5 text-gray-400 text-lg")], [
                    element.text("🔍"),
                  ]),
                  html.input([
                    attribute.type_("text"),
                    attribute.placeholder(
                      "Search free high-resolution photos",
                    ),
                    attribute.class(
                      "w-full px-4 py-4 text-gray-900 text-base sm:text-lg bg-transparent",
                    ),
                    attribute.attribute("readonly", "true"),
                  ]),
                ],
              ),
            ]),
          ],
        ),
      ],
    ),
    // Trending topics
    html.section(
      [attribute.class("max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16")],
      [
        html.h2(
          [attribute.class("text-xl font-semibold text-primary mb-6")],
          [element.text("Browse by topic")],
        ),
        html.div(
          [attribute.class("grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4")],
          [
            topic_card("🌿", "Nature"),
            topic_card("🏙️", "Architecture"),
            topic_card("🎨", "Art"),
            topic_card("💻", "Technology"),
            topic_card("🍕", "Food"),
            topic_card("✈️", "Travel"),
          ],
        ),
      ],
    ),
    // CTA section
    html.section(
      [
        attribute.class(
          "bg-surface-dim py-20 px-4 text-center",
        ),
      ],
      [
        html.div([attribute.class("max-w-2xl mx-auto")], [
          html.h2(
            [attribute.class("text-3xl font-bold text-primary mb-4")],
            [element.text("Join the community")],
          ),
          html.p([attribute.class("text-accent mb-8 text-lg")], [
            element.text(
              "Upload your photos and share them with the world.",
            ),
          ]),
          html.a(
            [
              attribute.href("/join"),
              attribute.class(
                "inline-block px-8 py-3 bg-primary text-white font-medium rounded-lg hover:bg-primary-hover transition-colors text-lg",
              ),
            ],
            [element.text("Get started →")],
          ),
        ]),
      ],
    ),
  ])
}

fn topic_card(emoji: String, label: String) -> Element(msg) {
  html.div(
    [
      attribute.class(
        "group relative bg-surface rounded-xl border border-border-light p-6 text-center hover:shadow-lg hover:-translate-y-1 transition-all duration-300 cursor-pointer",
      ),
    ],
    [
      html.div(
        [attribute.class("text-3xl mb-3 group-hover:scale-110 transition-transform duration-300")],
        [element.text(emoji)],
      ),
      html.p(
        [attribute.class("text-sm font-medium text-primary")],
        [element.text(label)],
      ),
    ],
  )
}
