import argus
import gleam/bool
import gleam/http
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import pog
import server/sql
import server/user
import server/web
import wisp

const auth_cookie = "uid"

pub fn require_login(
  context: web.Context,
  next: fn(user.User) -> wisp.Response,
) -> wisp.Response {
  case context.user {
    Some(user) -> next(user)
    None -> wisp.redirect("/" <> wisp.escape_html("User needs to be logged in"))
  }
}

pub fn login(request: wisp.Request, context: web.Context) -> wisp.Response {
  case request.method {
    http.Get -> todo
    http.Post -> login_attempt(request, context)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

pub fn logout(request, context) -> wisp.Response {
  todo
}

fn login_attempt(request: wisp.Request, context: web.Context) -> wisp.Response {
  use form <- wisp.require_form(request)

  let login_result = {
    use username <- result.try(list.key_find(form.values, "username"))
    use password <- result.try(list.key_find(form.values, "password"))
    use res <- result.try(
      sql.user_find_by_name(context.db, username)
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
    use first_name <- result.try(list.key_find(form.values, "first_name"))
    let last_name = result.unwrap(list.key_find(form.values, "last_name"), "")

    // TODO: think about using insecure salt
    use pass_hash <- result.try(
      argus.hasher()
      |> argus.hash(password, argus.gen_salt())
      |> result.replace_error(Nil),
    )

    sql.user_create(
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

// pub fn get_user_from_session(
//   request,
//   db: pog.Connection,
// ) -> Result(user.User, Nil) {
//   let user: Result(Option(user.User), Nil) =
//     wisp.get_cookie(request, auth_cookie, wisp.Signed)
//     |> result.map(user.get_user(db, _))

//   case user {
//     Ok(Some(user)) -> Ok(user)
//     _ -> Error(Nil)
//   }
// }

pub fn get_user_from_session(
  request,
  db: pog.Connection,
  next: fn(Option(user.User)) -> wisp.Response,
) -> wisp.Response {
  let user: Result(Option(user.User), Nil) =
    wisp.get_cookie(request, auth_cookie, wisp.Signed)
    |> result.map(user.get_user(db, _))

  case user {
    Ok(Some(user)) -> next(Some(user))
    Ok(None) ->
      wisp.response(403)
      |> wisp.set_cookie(request, auth_cookie, "", wisp.PlainText, 0)
    Error(_) -> next(None)
  }
}

// pub fn get_user_from_session_try(
//   request,
//   db: pog.Connection,
//   next: fn(Option(user.User)) -> wisp.Response,
// ) -> wisp.Response {
//   let user: Result(Option(user.User), Nil) =
//     wisp.get_cookie(request, auth_cookie, wisp.Signed)
//     |> result.map(user.get_user(db, _))

//   case user {
//     Ok(Some(user)) -> next(Some(user))
//     Ok(None) ->
//       wisp.response(403)
//       |> wisp.set_cookie(request, auth_cookie, "", wisp.PlainText, 0)
//     Error(_) -> next(None)
//   }
// }

pub fn get_user_from_session_try(
  request,
  db: pog.Connection,
  next: fn(user.User) -> wisp.Response,
) -> wisp.Response {
  let user: Result(Option(user.User), Nil) =
    wisp.get_cookie(request, auth_cookie, wisp.Signed)
    |> result.map(user.get_user(db, _))

  case user {
    Ok(Some(user)) -> next(user)
    _ ->
      wisp.response(403)
      |> wisp.set_cookie(request, auth_cookie, "", wisp.PlainText, 0)
  }
}
