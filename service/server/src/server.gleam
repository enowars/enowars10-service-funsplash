import gleam/erlang/process
import gleam/http/request
import gleam/option
import mist
import pog
import server/censor
import server/config.{type Config}
import server/router
import server/web
import server/web/auth
import wisp
import wisp/wisp_mist

fn server(db: pog.Connection, config: Config) -> Nil {
  wisp.configure_logger()

  let assert Ok(priv_directory) = wisp.priv_directory("server")
  let static_directory = priv_directory <> "/static"

  let handle_request = fn(request: wisp.Request) -> wisp.Response {
    use user <- auth.get_user_from_session(request, db)
    let context = web.Context(db, static_directory, user)
    router.handle_request(request, context)
  }

  let wisp_app = wisp_mist.handler(handle_request, config.server_secret)

  let mist_handler = fn(request: request.Request(mist.Connection)) {
    case request.path_segments(request) {
      ["napi", "censor", photo_id] -> censor.upgrade(request, photo_id, db)
      _ -> wisp_app(request)
    }
  }

  let assert Ok(_) =
    mist_handler
    |> mist.new
    |> mist.port(config.server_port)
    |> mist.bind(config.server_host)
    |> mist.start

  process.sleep_forever()
}

fn db(config: Config) {
  let db_proc = process.new_name("db")

  let assert Ok(_) =
    db_proc
    |> pog.default_config()
    |> pog.user(config.db_user)
    |> pog.password(option.Some(config.db_password))
    |> pog.host(config.db_host)
    |> pog.port(config.db_port)
    |> pog.database(config.db_database)
    |> pog.pool_size(config.db_pool_size)
    |> pog.start

  pog.named_connection(db_proc)
}

pub fn main() -> Nil {
  let config = config.config()
  let db_proc = db(config)
  server(db_proc, config)
}
