import bravo/uset.{type USet}
import formal/form
import gleam/bool
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri
import pog
import server/sql
import server/user.{type User}
import server/web
import shared/shared_login
import shared/shared_signup
import shared/shared_user
import utils
import wisp
import youid/uuid

pub const uid_cookie = "uid"

pub const uname_cookie = "uname"

pub fn require_login(
  context: web.Context,
  next: fn(User) -> wisp.Response,
) -> wisp.Response {
  case context.user {
    Some(user) -> next(user)
    None ->
      wisp.redirect(
        "/?error="
        <> shared_user.RequireLogin
        |> shared_user.error_to_uri,
      )
  }
}

pub fn login(request: wisp.Request, context: web.Context) -> wisp.Response {
  case request.method {
    http.Post -> login_attempt(request, context)
    _ -> wisp.method_not_allowed([http.Post])
  }
}

pub fn me(_request: wisp.Request, context: web.Context) -> wisp.Response {
  use user <- require_login(context)
  user
  |> user.to_shared([])
  |> shared_user.user_to_json()
  |> json.to_string()
  |> wisp.json_response(200)
}

pub fn logout(request, context: web.Context) -> wisp.Response {
  use user <- require_login(context)
  let _ = uset.delete_key(context.user_cache, user.id)
  wisp.ok() |> unset_cookies(request)
}

fn login_attempt(request: wisp.Request, context: web.Context) -> wisp.Response {
  use form_data <- wisp.require_form(request)

  let login_result = {
    use validated_form <- result.try(
      shared_login.form()
      |> form.add_values(form_data.values)
      |> form.run
      |> result.replace_error(shared_login.InvalidData),
    )
    use user <- utils.db_limit(
      sql.user_find_by_name(context.db, validated_form.username),
      shared_login.UserNotFound,
    )

    use <- bool.guard(
      // when: argus.verify(user.password, validated_form.password) != Ok(True),
      user.password != validated_form.password,
      return: Error(shared_login.InvalidCredentials),
    )

    let _ = uset.insert(context.user_cache, user.id, user)

    Ok(user)
  }

  case login_result {
    Ok(user) -> wisp.redirect("/") |> set_cookies(request, user)
    Error(e) -> wisp.redirect("/login?error=" <> shared_login.error_to_uri(e))
  }
}

fn set_cookies(response, request, user: User) {
  response
  |> wisp.set_cookie(
    request,
    uid_cookie,
    user.id |> uuid.to_string,
    wisp.Signed,
    60 * 10,
  )
  |> wisp.set_cookie(request, uname_cookie, user.username, wisp.Signed, 60 * 10)
}

pub fn sign_up(request: wisp.Request, context: web.Context) -> wisp.Response {
  use form_data <- wisp.require_form(request)
  let user = {
    use validated_form <- result.try(
      shared_signup.form()
      |> form.add_values(form_data.values)
      |> form.run
      |> result.replace_error(shared_signup.InvalidData),
    )

    // use pass_hash <- result.try(
    //   argus.hasher()
    //   |> argus.hash(validated_form.password, argus.gen_salt())
    //   |> result.replace_error(shared_signup.InternalError),
    // )

    use user <- utils.db_limit(
      sql.user_create(
        context.db,
        validated_form.username,
        validated_form.first_name,
        validated_form.last_name |> option.unwrap(""),
        validated_form.password,
        validated_form.bio |> option.unwrap(""),
        validated_form.available_for_hire,
      ),
      shared_signup.UserExists,
    )
    Ok(user)
  }
  case user {
    Ok(user) -> {
      let user = user |> user.from_user_create_row
      let _ = uset.insert_new(context.user_cache, user.id, user)
      set_cookies(wisp.redirect("/?registered=true"), request, user)
    }
    Error(e) -> wisp.redirect("/?error=" <> shared_signup.error_to_uri(e))
  }
}

fn unset_cookies(response, request) {
  response
  |> wisp.set_cookie(request, uid_cookie, "", wisp.PlainText, 0)
  |> wisp.set_cookie(request, uname_cookie, "", wisp.PlainText, 0)
}

pub fn get_user_from_session(
  request req: request.Request(wisp.Connection),
  db db: pog.Connection,
  user_cache cache: USet(uuid.Uuid, User),
  next next: fn(Option(User)) -> wisp.Response,
) -> wisp.Response {
  // TODO: use ets instead of hitting db everytime

  let user = {
    use uid <- result.try(
      wisp.get_cookie(req, uid_cookie, wisp.Signed)
      |> result.replace_error(user.LoggedOut),
    )
    use uid <- result.try(
      uid |> uuid.from_string |> result.replace_error(user.Invalid),
    )

    case uset.lookup(cache, uid) {
      Ok(user) -> Ok(user)
      Error(_) -> user.get_by_id(db, uid) |> result.replace_error(user.NotFound)
    }
  }

  case user {
    Ok(user) -> next(Some(user))
    Error(user.LoggedOut) -> next(None)
    Error(_) -> next(None) |> unset_cookies(req)
  }
}
