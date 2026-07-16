import api/api_collection
import auth
import components/photo_card
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h1, p}
import lustre/event
import rsvp
import shared/shared_collection
import shared/shared_thumbnail

pub type Model {
  Loading(
    id: String,
    collection: option.Option(shared_collection.Collection),
    photos: option.Option(List(shared_thumbnail.Thumbnail)),
  )
  Loaded(
    collection: shared_collection.Collection,
    photos: List(shared_thumbnail.Thumbnail),
    cards: dict.Dict(String, photo_card.Model),
  )
  Failed(error: String)
}

pub fn init(id: String) -> #(Model, Effect(Message)) {
  #(
    Loading(id, None, None),
    effect.batch([
      api_collection.fetch(id, ApiReturnedCollection),
      api_collection.fetch_photos(id, ApiReturnedPhotos),
    ]),
  )
}

pub type Message {
  ApiReturnedCollection(
    Result(shared_collection.Collection, rsvp.Error(String)),
  )
  ApiReturnedPhotos(
    Result(List(shared_thumbnail.Thumbnail), rsvp.Error(String)),
  )
  CardMsg(photo_id: String, msg: photo_card.Message)
  CloseAllDropdowns
}

pub fn update(model: Model, msg: Message) -> #(Model, Effect(Message)) {
  case msg {
    ApiReturnedCollection(Ok(collection)) -> {
      case model {
        Loading(id, _, p) -> check_loaded(id, Some(collection), p)
        Loaded(_, p, cards) -> #(Loaded(collection, p, cards), effect.none())
        _ -> #(model, effect.none())
      }
    }
    ApiReturnedCollection(Error(_)) -> #(
      Failed("Failed to load collection"),
      effect.none(),
    )
    ApiReturnedPhotos(Ok(photos)) -> {
      case model {
        Loading(id, c, _) -> check_loaded(id, c, Some(photos))
        Loaded(c, _, cards) -> {
          let new_cards =
            list.fold(photos, cards, fn(acc, p) {
              case dict.has_key(acc, p.public_id) {
                True -> acc
                False -> dict.insert(acc, p.public_id, photo_card.init(p))
              }
            })
          #(Loaded(c, photos, new_cards), effect.none())
        }
        _ -> #(model, effect.none())
      }
    }
    ApiReturnedPhotos(Error(_)) -> {
      // TTL fallback
      case model {
        Loading(id, c, _) -> check_loaded(id, c, Some([]))
        Loaded(c, _, cards) -> #(Loaded(c, [], cards), effect.none())
        _ -> #(model, effect.none())
      }
    }
    CardMsg(pid, m) ->
      case model {
        Loaded(col, photos, cards) -> {
          case dict.get(cards, pid) {
            Ok(card_model) -> {
              let #(new_card_model, eff) = photo_card.update(card_model, m)
              let new_cards = dict.insert(cards, pid, new_card_model)
              #(
                Loaded(col, photos, new_cards),
                effect.map(eff, fn(em) { CardMsg(pid, em) }),
              )
            }
            Error(_) -> #(model, effect.none())
          }
        }
        _ -> #(model, effect.none())
      }
    CloseAllDropdowns ->
      case model {
        Loaded(col, photos, cards) -> {
          let new_cards =
            dict.map_values(cards, fn(_, c) {
              let #(new_c, _) = photo_card.update(c, photo_card.CloseDropdown)
              new_c
            })
          #(Loaded(col, photos, new_cards), effect.none())
        }
        _ -> #(model, effect.none())
      }
  }
}

fn check_loaded(
  id: String,
  col: option.Option(shared_collection.Collection),
  photos: option.Option(List(shared_thumbnail.Thumbnail)),
) -> #(Model, Effect(Message)) {
  case col, photos {
    Some(c), Some(p) -> {
      let cards =
        list.fold(p, dict.new(), fn(acc, photo) {
          dict.insert(acc, photo.public_id, photo_card.init(photo))
        })
      #(Loaded(c, p, cards), effect.none())
    }
    _, _ -> #(Loading(id, col, photos), effect.none())
  }
}

pub fn view(model: Model, current_auth: auth.Auth) -> Element(Message) {
  div(
    [class("max-w-5xl mx-auto py-8 px-4"), event.on_click(CloseAllDropdowns)],
    [
      case model {
        Loading(_, _, _) ->
          p([class("text-center text-gray-500 py-20")], [
            text("Loading collection..."),
          ])
        Failed(err) -> p([class("text-center text-red-500 py-20")], [text(err)])
        Loaded(col, photos, cards) ->
          collection_view(col, photos, cards, current_auth)
      },
    ],
  )
}

fn collection_view(
  col: shared_collection.Collection,
  photos: List(shared_thumbnail.Thumbnail),
  cards: dict.Dict(String, photo_card.Model),
  current_auth: auth.Auth,
) -> Element(Message) {
  div([class("space-y-8")], [
    div([class("flex flex-col items-center text-center space-y-2 mb-8")], [
      h1([class("text-3xl font-bold text-gray-900")], [text(col.name)]),
      p([class("text-sm text-gray-500")], [
        text("By " <> col.user.first_name <> " (@" <> col.user.username <> ")"),
      ]),
      case col.description {
        Some(desc) -> p([class("text-sm text-gray-600 max-w-md")], [text(desc)])
        None -> element.none()
      },
      case col.private {
        True ->
          html.span(
            [
              class(
                "inline-block rounded-full bg-red-50 border border-red-200 px-3 py-0.5 text-xs text-red-700",
              ),
            ],
            [text("Private Collection")],
          )
        False -> element.none()
      },
    ]),
    case photos {
      [] ->
        p([class("text-center text-gray-400 text-sm py-8")], [
          text("No photos in this collection."),
        ])
      photos_list ->
        div(
          [class("grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4")],
          list.map(photos_list, fn(p) {
            case dict.get(cards, p.public_id) {
              Ok(card_model) ->
                element.map(photo_card.view(card_model, current_auth), fn(msg) {
                  CardMsg(p.public_id, msg)
                })
              Error(_) -> element.none()
            }
          }),
        )
    },
  ])
}
