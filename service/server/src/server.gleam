import gleam/erlang/process
import gleam/option
import mist
import pog
import server/router
import server/context
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

  let assert Ok(_) =
    router.handle_request(_, context)
    |> wisp_mist.handler("secret")
    |> mist.new
    |> mist.port(1337)
    |> mist.start

  process.sleep_forever()
}
