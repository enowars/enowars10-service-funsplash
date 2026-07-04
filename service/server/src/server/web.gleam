import bravo/oset
import bravo/uset.{type USet}
import gleam/option.{type Option}
import pog
import server/user.{type ProfileCache, type User, type UserCache}
import wisp
import youid/uuid.{type Uuid}

pub type Context {
  Context(
    db: pog.Connection,
    static_dir: String,
    user: Option(User),
    user_cache: UserCache,
    profile_cache: ProfileCache,
  )
}

pub fn middleware(
  req: wisp.Request,
  context: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.serve_static(req, under: "/", from: context.static_dir)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  handle_request(req)
}
