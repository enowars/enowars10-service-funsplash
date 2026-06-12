import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  html.div(
    [
      attribute.class(
        "min-h-[calc(100vh-12rem)] flex items-center justify-center px-4 py-16 animate-fade-in",
      ),
    ],
    [
      html.div([attribute.class("text-center max-w-md")], [
        html.div([attribute.class("text-8xl mb-8")], [element.text("🔍")]),
        html.h1(
          [attribute.class("text-4xl font-bold text-primary mb-4")],
          [element.text("Page not found")],
        ),
        html.p([attribute.class("text-accent mb-8 text-lg")], [
          element.text(
            "The page you're looking for doesn't exist or has been moved.",
          ),
        ]),
        html.a(
          [
            attribute.href("/"),
            attribute.class(
              "inline-block px-8 py-3 bg-primary text-white font-medium rounded-lg hover:bg-primary-hover transition-colors",
            ),
          ],
          [element.text("← Go home")],
        ),
      ]),
    ],
  )
}
