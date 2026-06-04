import gleam/bytes_tree.{type BytesTree}
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None}
import mist
import png/censor
import png/png.{type Compressed, type Uncompressed}
import pog
import server/sql
import youid/uuid

pub type State {
  State(
    id: uuid.Uuid,
    in_photo: png.Photo(BitArray, Uncompressed),
    out_photo: Option(png.Photo(BytesTree, Compressed)),
    z_stream: png.ZStream,
    owner: uuid.Uuid,
  )
}

// use websocket for future collaborative real-time editing
pub fn upgrade(
  request: request.Request(mist.Connection),
  id: String,
  db: pog.Connection,
) -> response.Response(mist.ResponseData) {
  let on_init = fn(_connection: mist.WebsocketConnection) -> #(
    State,
    Option(process.Selector(b)),
  ) {
    // FIXME: think about authentication
    io.println("Connected")
    let assert Ok(res) = sql.photo_find_by_public_id(db, id)

    let assert Ok(photo) = list.first(res.rows)
    let data = png.parse_photo(photo.data)
    let z_stream = png.init_compressor()
    #(State(photo.id, data, None, z_stream:, owner: photo.creator), None)
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
  png.close_compressor(state.z_stream)
  io.println("Disconnected")
}

fn handler(
  state: State,
  message: mist.WebsocketMessage(b),
  connection: mist.WebsocketConnection,
) {
  io.println("handle")
  // TODO: rate limit
  case message {
    mist.Binary(mask) -> {
      case censor.censor_raw(state.in_photo, mask, state.z_stream) {
        Ok(censored_png) -> {
          let state = State(..state, out_photo: option.Some(censored_png))
          // TODO: remove only here for debugging
          let _ = mist.send_binary_frame(connection, censored_png |> png.pack)
          let _ =
            mist.send_text_frame(
              connection,
              "ok.size:" <> int.to_string(png.size(censored_png)),
            )
          mist.continue(state)
        }
        Error(e) -> {
          let _ = mist.send_text_frame(connection, e)
          mist.continue(state)
        }
      }
    }
    mist.Shutdown -> mist.stop()
    mist.Closed -> mist.stop()
    mist.Text(_) -> mist.continue(state)
    // save
    _ -> mist.continue(state)
  }
}
