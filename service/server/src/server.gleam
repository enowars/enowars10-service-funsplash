import gleam/erlang/process
import gleam/http/request
import gleam/option
import mist
import pog
import server/censor
import server/context
import server/router
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  // db
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

  // webserver
  let context = context.Context(pog.named_connection(db_proc), "/public")
  wisp.configure_logger()

  let wisp_app = wisp_mist.handler(router.wisp_handler(_, context), "secret")

  let mist_handler = fn(req: request.Request(mist.Connection)) {
    case request.path_segments(req) {
      ["censor"] -> censor.upgrade(req)
      _ -> wisp_app(req)
    }
  }

  let assert Ok(_) =
    mist_handler
    |> mist.new
    |> mist.port(1337)
    |> mist.start

  process.sleep_forever()
}
