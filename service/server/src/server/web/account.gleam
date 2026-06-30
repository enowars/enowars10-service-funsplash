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
  use user <- auth.require_login(context)
  use form_data <- wisp.require_form(request)

  let new_user = {
    use f <- result.try(
      shared_account.edit_form()
      |> form.add_values(form_data.values)
      |> form.run
      |> result.replace_error(shared_account.InvalidData),
    )

    let id =
      uset.lookup(context.profile_cache, f.username) |> option.from_result

    let new_user = case id {
      Some(id) -> {
        let _ = uset.insert_new(context.profile_cache, f.username, id)
        Error(shared_account.UsernameExists)
      }
      None -> {
        use new_user <- utils.db_limit(
          sql.user_update(
            context.db,
            user.id,
            f.username,
            f.first_name,
            f.last_name |> option.unwrap(""),
            f.bio |> option.unwrap(""),
            f.available_for_hire,
          ),
          shared_account.UsernameExists,
        )
        let _ = uset.delete_key(context.profile_cache, user.username)
        Ok(new_user)
      }
    }

    let _ = uset.insert_new(context.profile_cache, f.username, user.id)

    new_user
  }

  case new_user {
    Ok(new_user) -> {
      let user = new_user |> user.from_user_update
      let _ = uset.insert_new(context.user_cache, user.id, user)
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
