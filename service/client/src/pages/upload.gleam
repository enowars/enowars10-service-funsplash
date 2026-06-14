import gleam/list
import lustre/attribute as a
import lustre/element
import lustre/element/html as h
import shared/shared_privacy.{type Privacy, Premium, Private, Public}

pub fn privacy_select(current: Privacy) -> element.Element(msg) {
  // 1. Define the exhaustive list of your options
  let all_options = [Public, Premium, Private]

  // 2. Map over the list to generate the HTML <option> elements
  let option_elements =
    list.map(all_options, fn(variant) {
      h.option(
        [
          a.value(shared_privacy.to_string(variant)),
          a.selected(current == variant),
        ],
        shared_privacy.to_string(variant),
      )
    })

  // 3. Inject the generated list into the <select> element
  h.select([a.name("privacy_level")], option_elements)
}

// Assuming your Lustre model has a list of tags: ["gleam", "web", "lustre"]
pub fn tags_form_inputs(current_tags: List(String)) {
  let hidden_inputs =
    list.map(current_tags, fn(tag) {
      h.input([
        a.type_("hidden"),
        a.name("tags"),
        // They all share the name "tags"
        a.value(tag),
      ])
    })

  // Render these inside your form alongside your visible UI
  h.div([], hidden_inputs)
}
