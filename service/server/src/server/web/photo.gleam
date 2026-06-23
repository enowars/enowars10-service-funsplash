import formal/form
import gleam/bytes_tree
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import server/photo
import server/premium
import server/sql
import server/web
import server/web/auth
import shared/shared_photo
import shared/shared_privacy.{Premium, Private, Public}
import shared/shared_upload
import simplifile
import wisp

pub fn get_data_private(
  _request: wisp.Request,
  context: web.Context,
  asset_id: String,
) -> wisp.Response {
  use user <- auth.require_login(context)

  case photo.get_data(asset_id, context.db, Private) {
    Ok(photo) -> {
      let body = case user.id {
        id if id == photo.creator ->
          wisp.Bytes(photo.data |> bytes_tree.from_bit_array)
        _ ->
          wisp.Bytes(photo.data |> premium.censor |> bytes_tree.from_bit_array)
      }
      wisp.ok()
      |> wisp.set_header("content-type", "image/png")
      |> wisp.set_body(body)
    }
    Error(_) -> wisp.not_found()
  }
}

pub fn get_data_premium(
  _request: wisp.Request,
  context: web.Context,
  asset_id: String,
) -> wisp.Response {
  case photo.get_data(asset_id, context.db, Premium) {
    Ok(photo) -> {
      let body = case context.user {
        Some(user) if user.premium == True ->
          wisp.Bytes(photo.data |> bytes_tree.from_bit_array)
        Some(user) if user.id == photo.creator ->
          wisp.Bytes(photo.data |> bytes_tree.from_bit_array)
        _ ->
          wisp.Bytes(photo.data |> premium.censor |> bytes_tree.from_bit_array)
      }
      wisp.ok()
      |> wisp.set_header("content-type", "image/png")
      |> wisp.set_body(body)
    }
    Error(_) -> wisp.not_found()
  }
}

pub fn get_data_public(
  _request: wisp.Request,
  context: web.Context,
  asset_id: String,
) -> wisp.Response {
  case photo.get_data(asset_id, context.db, Public) {
    Ok(photo) -> {
      wisp.ok()
      |> wisp.set_header("content-type", "image/png")
      |> wisp.set_body(wisp.Bytes(photo.data |> bytes_tree.from_bit_array))
    }
    Error(_) -> wisp.not_found()
  }
}

pub fn get(
  _request: wisp.Request,
  context: web.Context,
  public_id: String,
) -> wisp.Response {
  let result = {
    use res <- result.try(
      sql.photo_find_by_public_id(context.db, public_id)
      |> result.replace_error(wisp.not_found()),
    )
    use photo <- result.try(
      res.rows |> list.first |> result.replace_error(wisp.not_found()),
    )

    use res <- result.try(
      sql.user_find_by_id(context.db, photo.creator)
      |> result.replace_error(wisp.internal_server_error()),
    )
    use user <- result.try(
      res.rows
      |> list.first
      |> result.replace_error(wisp.internal_server_error()),
    )

    let tags = photo.get_tags(context.db, photo.id)

    let user_liked = case context.user {
      Some(viewer) -> photo.user_liked(context.db, photo.id, viewer.id)
      None -> False
    }

    let response =
      photo
      |> photo.from_photo_find_by_public_id_row
      |> photo.to_shared(user.username, tags, user_liked)
      |> shared_photo.photo_to_json
      |> json.to_string
      |> wisp.json_response(200)

    Ok(response)
  }

  case result {
    Ok(response) -> response
    Error(error_response) -> error_response
  }
}

pub fn upload(request: wisp.Request, context: web.Context) -> wisp.Response {
  use user <- auth.require_login(context)

  use multipart <- wisp.require_form(request)

  let upload_result = {
    use photo_file <- result.try(
      list.key_find(multipart.files, "photo")
      |> result.replace_error(shared_upload.FileMissing),
    )
    use data <- result.try(
      simplifile.read_bits(photo_file.path)
      |> result.replace_error(shared_upload.FileReadError),
    )

    use form <- result.try(
      shared_upload.upload_form(user.id, data)
      |> form.add_values(multipart.values)
      |> form.run
      |> result.replace_error(shared_upload.InvalidForm),
    )

    form
    |> photo.upload(context.db)
  }

  case upload_result {
    Ok(_) -> wisp.redirect("/?upload_successful")
    Error(err) -> {
      wisp.redirect("/?error=" <> shared_upload.error_to_uri(err))
    }
  }
}
