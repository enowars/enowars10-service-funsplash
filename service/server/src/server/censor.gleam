import censor/censor
import gleam/http/request
import gleam/http/response
import gleam/option
import mist
import simplifile

pub type WsState =
  #(censor.ZStream, censor.Photo)

pub fn upgrade(
  request: request.Request(mist.Connection),
) -> response.Response(mist.ResponseData) {
  mist.websocket(
    request:,
    on_init: init_socket,
    handler: handler,
    on_close: close_socket,
  )
}

fn close_socket(state: WsState) -> Nil {
  let #(z_stream, _) = state
  censor.close_compressor(z_stream)
}

fn handler(
  state: WsState,
  message: mist.WebsocketMessage(b),
  connection: mist.WebsocketConnection,
) {
  let #(z_stream, photo) = state

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

fn init_socket(
  _connection: mist.WebsocketConnection,
) -> #(WsState, option.Option(_)) {
  let z_stream = censor.init_compressor()
  let assert Ok(raw_file) = simplifile.read_bits("test.png")

  let photo = censor.parse_photo(raw_file)

  #(#(z_stream, photo), option.None)
}
