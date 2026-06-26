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
import simplifile

fn server(db: pog.Connection, bg_db: pog.Connection, config: Config) -> Nil {
  let _ = simplifile.create_directory_all("/app/data/photos")
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
      ["napi", "censor", photo_id] ->
        censor.upgrade(request, photo_id, db, bg_db)
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
    |> pog.pool_size(100)
    |> pog.start

  pog.named_connection(db_proc)
}

fn bg_db(config: Config) {
  let db_proc = process.new_name("db_bg")

  let assert Ok(_) =
    db_proc
    |> pog.default_config()
    |> pog.user(config.db_user)
    |> pog.password(option.Some(config.db_password))
    |> pog.host(config.db_host)
    |> pog.port(config.db_port)
    |> pog.database(config.db_database)
    |> pog.pool_size(80)
    |> pog.start

  pog.named_connection(db_proc)
}

pub fn main() -> Nil {
  let config = config.config()
  let db_proc = db(config)
  let bg_db_proc = bg_db(config)
  server(db_proc, bg_db_proc, config)
}
