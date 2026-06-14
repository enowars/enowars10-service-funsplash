import gleam/uri.{type Uri}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import pages/photo
import pages/profile
import route

pub fn init(initial_uri: Result(Uri, Nil)) -> #(Page, Effect(Message)) {
  case initial_uri {
    Ok(uri) -> route.parse(uri)
    Error(_) -> route.Index
  }
  |> page_from_route
}

pub type Page {
  PhotoPage(model: photo.Model)
  ProfilePage(model: profile.Model)
}

pub type Message {
  OnRouteChanged(route: route.Route)
  PhotoPageSentMessage(message: photo.Message)
  ProfilePageSentMessage(message: profile.Message)
}

pub fn update(page: Page, msg: Message) -> #(Page, Effect(Message)) {
  case msg, page {
    OnRouteChanged(route), _ -> page_from_route(route)
    PhotoPageSentMessage(p_msg), PhotoPage(p_model) -> {
      let #(model, effect) = photo.update(p_model, p_msg)
      #(PhotoPage(model), effect.map(effect, PhotoPageSentMessage))
    }
    ProfilePageSentMessage(p_msg), ProfilePage(p_model) -> {
      let #(model, effect) = profile.update(p_model, p_msg)
      #(ProfilePage(model), effect.map(effect, ProfilePageSentMessage))
    }
    _, _ -> panic as "wrong page sent wrong message"
  }
}

pub fn page_from_route(route: route.Route) -> #(Page, Effect(Message)) {
  case route {
    route.Photo(id) -> {
      let #(page_model, effect) = photo.init(id)
      #(PhotoPage(page_model), effect.map(effect, PhotoPageSentMessage))
    }
    _ -> todo
  }
}

pub fn view(page: Page) -> Element(Message) {
  case page {
    PhotoPage(model:) -> photo.view(model) |> element.map(PhotoPageSentMessage)
    ProfilePage(model:) ->
      profile.view(model) |> element.map(ProfilePageSentMessage)
  }
}

pub fn on_url_change(uri: Uri) -> Message {
  OnRouteChanged(route.parse(uri))
}
