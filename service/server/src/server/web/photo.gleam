import formal/form
import gleam/bool
import gleam/bytes_tree
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import pog
import server/photo
import server/premium
import server/sql
import server/web
import server/web/auth
import shared/shared_photo
import shared/shared_privacy.{Premium, Private, Public}
import shared/shared_upload
import simplifile
import utils
import wisp
import youid/uuid

fn get_meta(
  db: pog.Connection,
  asset_id: String,
  privacy: shared_privacy.Privacy,
) -> Result(sql.PhotoFindByAssetIdRow, Nil) {
  use asset_id <- result.try(uuid.from_string(asset_id))
  use res <- result.try(
    sql.photo_find_by_asset_id(db, asset_id, privacy |> photo.privacy_to_sql)
    |> result.replace_error(Nil),
  )
  res.rows |> list.first
}

pub fn get_data_private(
  _request: wisp.Request,
  context: web.Context,
  asset_id: String,
) -> wisp.Response {
  use user <- auth.require_login(context)

  use photo <- utils.result_guard(
    get_meta(context.db, asset_id, Private),
    wisp.not_found(),
  )

  use <- bool.guard(photo.creator != user.id, wisp.response(403))

  use data <- utils.result_guard(
    photo.get_data(Private, photo.asset_id),
    wisp.response(500),
  )

  wisp.ok()
  |> wisp.set_header("content-type", "image/png")
  |> wisp.set_body(data |> bytes_tree.from_bit_array |> wisp.Bytes)
}

pub fn get_data_premium(
  _request: wisp.Request,
  context: web.Context,
  asset_id: String,
) -> wisp.Response {
  use photo <- utils.result_guard(
    get_meta(context.db, asset_id, Premium),
    wisp.not_found(),
  )

  use data <- utils.result_guard(
    photo.get_data(Premium, photo.asset_id),
    wisp.response(500),
  )

  let data = case context.user {
    Some(user) if user.id == photo.creator || user.premium == True -> data
    _ -> data |> premium.censor
  }

  wisp.ok()
  |> wisp.set_header("content-type", "image/png")
  |> wisp.set_body(data |> bytes_tree.from_bit_array |> wisp.Bytes)
}

pub fn get_data_public(
  _request: wisp.Request,
  _context: web.Context,
  asset_id: String,
) -> wisp.Response {
  // TODO: move photo files into privacy dirs /public /private etc. so we dont have to call db here
  use asset_id <- utils.result_guard(
    asset_id |> uuid.from_string,
    wisp.not_found(),
  )

  case photo.get_data(Public, asset_id) {
    Ok(data) -> {
      wisp.ok()
      |> wisp.set_header("content-type", "image/png")
      |> wisp.set_body(wisp.Bytes(data |> bytes_tree.from_bit_array))
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
    use file <- result.try(
      list.key_find(multipart.files, "photo")
      |> result.replace_error(shared_upload.FileMissing),
    )
    use info <- result.try(
      simplifile.file_info(file.path)
      |> result.replace_error(shared_upload.FileReadError),
    )

    let data = shared_upload.File(file.path, info.size)

    use form <- result.try(
      shared_upload.upload_form(user.id, data)
      |> form.add_values(multipart.values)
      |> form.run
      |> result.replace_error(shared_upload.InvalidForm),
    )

    form
    |> photo.upload(context.db, context.user_cache)
  }

  case upload_result {
    Ok(_) -> wisp.redirect("/?upload_successful")
    Error(err) -> {
      wisp.redirect("/?error=" <> shared_upload.error_to_uri(err))
    }
  }
}

pub fn user_liked(
  request: wisp.Request,
  context: web.Context,
) -> wisp.Response {
  todo
}
