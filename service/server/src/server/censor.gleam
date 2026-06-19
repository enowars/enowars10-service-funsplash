import gleam/bool
import gleam/bytes_tree.{type BytesTree}
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import mist
import png/censor
import png/png.{type Compressed, type Uncompressed}
import pog
import server/photo
import server/sql
import shared/shared_privacy.{Private}
import shared/shared_upload
import utils
import youid/uuid

const ressource_limit = 900

pub type State {
  State(
    photo: photo.Photo,
    in_photo: png.Photo(BitArray, Uncompressed),
    out_photo: Option(png.Photo(BytesTree, Compressed)),
    req_counter: Int,
    z_stream: png.ZStream,
    user: uuid.Uuid,
    db: pog.Connection,
  )
}

// use websocket for future collaborative real-time editing
pub fn upgrade(
  request: request.Request(mist.Connection),
  public_id: String,
  db: pog.Connection,
) -> response.Response(mist.ResponseData) {
  // mist doesnt have built in signed cookie checks so we just dont them here
  // let assert Ok(auth_cookie) =
  //   request.get_cookies(request) |> list.key_find(auth.auth_cookie)
  // let assert Ok(uid) = auth_cookie |> uuid.from_string
  let uid = uuid.v7()

  io.println("Connected")
  let assert Ok(res) = sql.photo_find_by_public_id(db, public_id)
  let assert Ok(photo_row) = list.first(res.rows)
  let photo = photo_row |> photo.from_photo_find_by_public_id_row

  use <- bool.guard(
    photo.privacy == Private && uid != photo.creator,
    response.new(403) |> response.set_body(mist.Bytes(bytes_tree.new())),
  )

  let on_init = fn(_connection: mist.WebsocketConnection) -> #(
    State,
    Option(process.Selector(b)),
  ) {
    let data = png.parse_photo(photo_row.data)
    let z_stream = png.init_compressor()
    #(
      State(
        photo:,
        in_photo: data,
        out_photo: None,
        req_counter: 0,
        z_stream:,
        user: uid,
        db:,
      ),
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
  use <- utils.defer(fn() {
    png.close_compressor(state.z_stream)
    io.println("Disconnected")
  })
  let p = state.photo
  // TODO: check if editing allowed
  use <- bool.guard(state.user != p.creator, Nil)
  {
    use data <- option.map(state.out_photo)
    shared_upload.Upload(
      creator: p.creator,
      description: p.description,
      privacy: p.privacy,
      location: p.location,
      camera: p.camera,
      show_on_profile: p.show_on_profile,
      data: data |> png.pack,
      tags: [],
    )
    |> photo.upload(state.db)
  }
  Nil
}

fn handler(
  state: State,
  message: mist.WebsocketMessage(b),
  connection: mist.WebsocketConnection,
) {
  use <- bool.guard(state.req_counter >= ressource_limit, mist.stop())
  let state = State(..state, req_counter: state.req_counter + 1)
  case message {
    mist.Binary(mask) -> {
      case censor.censor_raw(state.in_photo, mask, state.z_stream) {
        Ok(censored_png) -> {
          let state = State(..state, out_photo: Some(censored_png))
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
