import censor/censor
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option
import gleam/result
import mist
import pog
import server/sql
import youid/uuid

pub type WsState =
  #(censor.ZStream, censor.Photo)

pub fn upgrade(
  request: request.Request(mist.Connection),
  photo_id: String,
  db: pog.Connection,
) -> response.Response(mist.ResponseData) {
  let on_init = fn(_connection: mist.WebsocketConnection) {
    // FIXME: think about authentication
    // Load photo from the database using the photo_id
    let assert Ok(photo) = {
      use id <- result.try(uuid.from_string(photo_id))
      use res <- result.try(
        sql.find_photo_by_id(db, id) |> result.replace_error(Nil),
      )
      use photo <- result.try(list.first(res.rows))
      Ok(censor.parse_photo(photo.photo))
    }
    let z_stream = censor.init_compressor()
    #(#(z_stream, photo), option.None)
  }

  mist.websocket(
    request:,
    on_init: on_init,
    handler: handler,
    on_close: close_socket,
  )
}

fn close_socket(state: WsState) -> Nil {
  let #(z_stream, photo) = state
  // TODO: check if user is allowed and write picture to db
  censor.close_compressor(z_stream)
}

fn handler(
  state: WsState,
  message: mist.WebsocketMessage(b),
  connection: mist.WebsocketConnection,
) {
  let #(z_stream, photo) = state
  // TODO: return size
  case message {
    mist.Binary(mask) -> {
      case censor.censor_png(photo, z_stream, mask) {
        Ok(censored_png) -> {
          let _ = mist.send_binary_frame(connection, censored_png)
          mist.continue(state)
        }
        Error(_) -> mist.continue(state)
      }
    }
    mist.Shutdown -> mist.stop()
    _ -> mist.continue(state)
  }
}
