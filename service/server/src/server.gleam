import gleam/erlang/process
import gleam/http/request
import gleam/option
import mist
import pog
import server/censor
import server/config
import server/router
import server/web
import server/web/auth
import wisp
import wisp/wisp_mist

fn server(db: pog.Connection, config: config.Config) -> Nil {
  wisp.configure_logger()

  let handle_request = fn(request: wisp.Request) -> wisp.Response {
    use user <- auth.get_user_from_session(request, db)
    let context = web.Context(db, "/public", user)
    router.handle_request(request, context)
  }

  let wisp_app = wisp_mist.handler(handle_request, config.secret)

  let mist_handler = fn(request: request.Request(mist.Connection)) {
    case request.path_segments(request) {
      ["censor", photo_id] -> censor.upgrade(request, photo_id, db)
      _ -> wisp_app(request)
    }
  }

  let assert Ok(_) =
    mist_handler
    |> mist.new
    |> mist.port(1337)
    |> mist.start

  process.sleep_forever()
}

fn db(_config) {
  let db_proc = process.new_name("db")

  let assert Ok(_) =
    db_proc
    |> pog.default_config()
    |> pog.user("felix")
    |> pog.password(option.Some("felix"))
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("funsplash_db")
    |> pog.pool_size(15)
    |> pog.start

  pog.named_connection(db_proc)
}

pub fn main() -> Nil {
  let config = config.config()
  let db_proc = db(config)
  server(db_proc, config)
}
