import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri
import layout
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import modem
import pages/auth
import pages/collection
import pages/home
import pages/not_found
import pages/photo
import pages/profile
import pages/upload
import router.{type Route}
import rsvp
import shared/shared_photo
import shared/shared_user

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", [])
  Nil
}

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(
    route: Route,
    auth_user: Option(String),
    photo_page: photo.Model,
    profile_page: profile.Model,
    error: Option(String),
    success: Option(String),
  )
}

// MESSAGES --------------------------------------------------------------------

pub type Msg {
  OnRouteChange(Route)
  GotMe(Result(String, rsvp.Error(String)))
  GotPhoto(Result(shared_photo.Photo, rsvp.Error(String)))
  GotProfile(Result(shared_user.User, rsvp.Error(String)))
}

// INIT ------------------------------------------------------------------------

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  let initial_uri = modem.initial_uri()
  let route =
    initial_uri
    |> result.map(router.parse_route)
    |> result.unwrap(router.Index)

  let error = get_query_param(initial_uri, "error")
  let success = get_query_param(initial_uri, "success")

  let model =
    Model(
      route: route,
      auth_user: None,
      photo_page: photo.NotLoaded,
      profile_page: profile.NotLoaded,
      error: error,
      success: success,
    )

  let effects =
    effect.batch([
      modem.init(fn(uri) { OnRouteChange(router.parse_route(uri)) }),
      fetch_me(),
      fetch_for_route(route),
    ])

  #(model, effects)
}

// UPDATE ----------------------------------------------------------------------

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    OnRouteChange(route) -> {
      let model = case route {
        router.PhotoById(_) ->
          Model(
            ..model,
            route: route,
            photo_page: photo.Loading,
            error: None,
            success: None,
          )
        router.UserByName(_) ->
          Model(
            ..model,
            route: route,
            profile_page: profile.Loading,
            error: None,
            success: None,
          )
        _ -> Model(..model, route: route, error: None, success: None)
      }
      #(model, fetch_for_route(route))
    }

    GotMe(Ok(username)) -> #(
      Model(..model, auth_user: Some(username)),
      effect.none(),
    )
    GotMe(Error(_)) -> #(Model(..model, auth_user: None), effect.none())

    GotPhoto(Ok(p)) -> #(
      Model(..model, photo_page: photo.Loaded(p)),
      effect.none(),
    )
    GotPhoto(Error(_)) -> #(
      Model(..model, photo_page: photo.Error),
      effect.none(),
    )

    GotProfile(Ok(user)) -> #(
      Model(..model, profile_page: profile.Loaded(user)),
      effect.none(),
    )
    GotProfile(Error(_)) -> #(
      Model(..model, profile_page: profile.Error),
      effect.none(),
    )
  }
}

fn fetch_me() -> effect.Effect(Msg) {
  let decoder = {
    use username <- decode.field("username", decode.string)
    decode.success(username)
  }
  let handler = rsvp.expect_json(decoder, GotMe)
  rsvp.get("/me", handler)
}

fn fetch_for_route(route: Route) -> effect.Effect(Msg) {
  case route {
    router.PhotoById(id:) -> {
      let handler =
        rsvp.expect_json(shared_photo.photo_decoder(), GotPhoto)
      rsvp.get("/photos/" <> id, handler)
    }
    router.UserByName(name:) -> {
      let handler =
        rsvp.expect_json(shared_user.user_decoder(), GotProfile)
      rsvp.get("/@" <> name, handler)
    }
    _ -> effect.none()
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div(
    [attribute.class("min-h-screen bg-white text-gray-900 flex flex-col font-sans")],
    [
      layout.navbar(model.route, model.auth_user),
      html.main([attribute.class("flex-1")], [page_view(model)]),
      layout.footer(),
    ],
  )
}

fn page_view(model: Model) -> Element(Msg) {
  case model.route {
    router.Index -> home.view(model.success)
    router.Login -> auth.login_view(model.error, model.success)
    router.Join -> auth.signup_view(model.error)
    router.PhotoById(_) -> photo.view(model.photo_page)
    router.UserByName(_) -> profile.view(model.profile_page, model.auth_user)
    router.CollectionById(_) -> collection.view()
    router.Upload -> upload.view(model.error)
    router.NotFound -> not_found.view()
  }
}

// UTILS -----------------------------------------------------------------------

fn get_query_param(initial_uri_result: Result(uri.Uri, Nil), key: String) -> Option(String) {
  case initial_uri_result {
    Ok(uri) -> {
      case uri.query {
        Some(q) -> {
          case uri.parse_query(q) {
            Ok(pairs) -> {
              case list.key_find(pairs, key) {
                Ok(val) -> Some(val)
                Error(_) -> None
              }
            }
            Error(_) -> None
          }
        }
        None -> None
      }
    }
    Error(_) -> None
  }
}
