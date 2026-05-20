import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import mist
import png/censor
import png/photo
import pog
import server/sql
import youid/uuid

pub type State {
  State(
    id: uuid.Uuid,
    in_photo: photo.Photo(photo.Uncompressed),
    out_photo: Option(photo.Photo(photo.Compressed)),
    z_stream: photo.ZStream,
    owner: uuid.Uuid,
  )
}

// fake TODO: use websocket for collaborative editing
pub fn upgrade(
  request: request.Request(mist.Connection),
  photo_id: String,
  db: pog.Connection,
) -> response.Response(mist.ResponseData) {
  let on_init = fn(_connection: mist.WebsocketConnection) {
    // FIXME: think about authentication
    // Load photo from the database using the photo_id
    let assert Ok(photo_id) = uuid.from_string(photo_id)
    let assert Ok(photo) = {
      use res <- result.try(
        sql.find_photo_by_id(db, photo_id) |> result.replace_error(Nil),
      )
      use photo <- result.try(list.first(res.rows))
      Ok(photo.parse_photo(photo.photo))
    }
    let assert Ok(owner) = {
      use res <- result.try(
        sql.find_photo_creator(db, photo_id) |> result.replace_error(Nil),
      )
      use res <- result.try(list.first(res.rows))
      Ok(res.creator)
    }
    #(
      State(photo_id, photo, None, z_stream: photo.init_compressor(), owner:),
      None,
    )
  }

  mist.websocket(
    request:,
    on_init: on_init,
    handler: handler,
    on_close: close_socket,
  )
}

fn close_socket(state: State) -> Nil {
  // TODO: check if user is allowed and write picture to db
  // copy prev
  photo.close_compressor(state.z_stream)
}

fn handler(
  state: State,
  message: mist.WebsocketMessage(b),
  connection: mist.WebsocketConnection,
) {
  // TODO: return size
  case message {
    mist.Binary(mask) -> {
      case censor.censor_raw(state.in_photo, mask, state.z_stream) {
        Ok(censored_png) -> {
          let state = State(..state, out_photo: option.Some(censored_png))
          // let _ = mist.send_binary_frame(connection, censored_png)
          let _ =
            mist.send_text_frame(
              connection,
              "ok.size:" <> int.to_string(photo.size(censored_png)),
            )
          mist.continue(state)
        }
        Error(_) -> mist.continue(state)
      }
    }
    mist.Shutdown -> mist.stop()
    mist.Text(message) -> todo
    // save
    _ -> mist.continue(state)
  }
}
