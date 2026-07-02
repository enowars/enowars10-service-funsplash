import bravo/uset
import formal/form
import gleam/bool
import gleam/option.{None, Some}
import gleam/result
import server/sql
import server/user
import server/web
import server/web/auth
import shared/shared_account
import utils
import wisp

pub fn update(request: wisp.Request, context: web.Context) -> wisp.Response {
  use context_user <- auth.require_login(context)
  use form_data <- wisp.require_form(request)

  let new_user = {
    use form <- result.try(
      shared_account.edit_form()
      |> form.add_values(form_data.values)
      |> form.run
      |> result.replace_error(shared_account.InvalidData),
    )
    let username = form.username
    let id = context_user.id

    // TODO: maybe delete old first and insert new or restore later

    case uset.lookup(context.profile_cache, username) |> option.from_result {
      // username exists in cache
      Some(_) -> Error(shared_account.UsernameExists)
      // username doesn't exists in cache
      None -> {
        let new_user = case
          utils.db_limit(sql.user_find_by_name(context.db, username))
        {
          // username exists in db so dont update
          Ok(user) -> Ok(user |> user.from_user_find_by_name)
          // username doesn't exists in db, so update existing entry
          Error(_) -> {
            use new_user <- utils.db_limit_try(
              sql.user_update(
                context.db,
                id,
                username,
                form.first_name,
                form.last_name |> option.unwrap(""),
                form.bio |> option.unwrap(""),
                form.available_for_hire,
              ),
              shared_account.UsernameExists,
            )
            Ok(new_user |> user.from_user_update)
          }
        }
        let _ = uset.delete_key(context.user_cache, id)
        let _ = uset.insert_new(context.profile_cache, username, id)
        new_user
      }
    }
  }

  case new_user {
    Ok(new_user) -> {
      let _ = uset.insert_new(context.user_cache, new_user.id, new_user)
      wisp.redirect("/?ok")
    }
    Error(e) -> wisp.redirect("/?error=" <> shared_account.error_to_uri(e))
  }
}

pub fn change_password(
  request: wisp.Request,
  context: web.Context,
) -> wisp.Response {
  use user <- auth.require_login(context)
  use form_data <- wisp.require_form(request)

  let change_result = {
    use f <- result.try(
      shared_account.change_password_form()
      |> form.add_values(form_data.values)
      |> form.run
      |> result.replace_error(shared_account.InvalidData),
    )

    let update_res = sql.user_update_password(context.db, user.id, f.new)
    use <- bool.guard(
      result.is_error(update_res),
      Error(shared_account.InternalError),
    )

    Ok(Nil)
  }

  case change_result {
    Ok(_) -> wisp.redirect("/account/password?ok=true")
    Error(e) ->
      wisp.redirect(
        "/account/password?error=" <> shared_account.error_to_uri(e),
      )
  }
}
