import argus
import pog

import gleam/bool

import gleam/http
import gleam/http/request
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import server/sql
import server/user.{type User}
import server/web
import wisp

const auth_cookie = "uid"

pub fn require_login(
  context: web.Context,
  next: fn(User) -> wisp.Response,
) -> wisp.Response {
  case context.user {
    Some(user) -> next(user)
    None -> wisp.redirect("/" <> wisp.escape_html("User needs to be logged in"))
  }
}

pub fn login(request: wisp.Request, context: web.Context) -> wisp.Response {
  case request.method {
    http.Get -> todo
    http.Post -> login_post(request, context)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn login_post(request: wisp.Request, context: web.Context) -> wisp.Response {
  use form <- wisp.require_form(request)

  let login_result = {
    use username <- result.try(list.key_find(form.values, "username"))
    use password <- result.try(list.key_find(form.values, "password"))
    use res <- result.try(
      sql.find_user_by_name(context.db, username)
      |> result.replace_error(Nil),
    )
    use user <- result.try(list.first(res.rows))
    use <- bool.guard(
      when: argus.verify(user.password, password) != Ok(True),
      return: Error(Nil),
    )
    Ok(user)
  }

  case login_result {
    Ok(user) ->
      wisp.redirect("/")
      |> wisp.set_cookie(
        request,
        auth_cookie,
        user.username,
        wisp.Signed,
        60 * 60,
      )
    Error(_) ->
      wisp.redirect(
        "/login?error" <> wisp.escape_html("username or password wrong"),
      )
  }
}

pub fn sign_up(request: wisp.Request, context: web.Context) -> wisp.Response {
  use form <- wisp.require_form(request)
  let res = {
    use username <- result.try(list.key_find(form.values, "username"))
    use password <- result.try(list.key_find(form.values, "password"))
    use first_name <- result.try(list.key_find(form.values, "firstname"))
    let last_name = result.unwrap(list.key_find(form.values, "lastname"), "")

    // TODO: think about using insecure salt
    use pass_hash <- result.try(
      argus.hasher()
      |> argus.hash(password, argus.gen_salt())
      |> result.replace_error(Nil),
    )

    sql.create_user(
      context.db,
      username,
      first_name,
      last_name,
      pass_hash.encoded_hash,
    )
    |> result.replace_error(Nil)
  }
  // TODO: give better error messages
  case res {
    Ok(_) -> wisp.ok()
    Error(_) -> wisp.bad_request("Invalid data")
  }
}

pub fn get_user_from_session(
  request,
  db: pog.Connection,
  next: fn(Option(User)) -> wisp.Response,
) -> wisp.Response {
  let user: Result(Option(User), Nil) =
    wisp.get_cookie(request, auth_cookie, wisp.Signed)
    |> result.map(user.get_user(db, _))

  case user {
    Ok(Some(user)) -> next(Some(user))
    Ok(None) ->
      wisp.not_found()
      |> wisp.set_cookie(request, auth_cookie, "", wisp.PlainText, 0)
    Error(_) -> next(None)
  }
}
