import gleam/bytes_tree
import gleam/http
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import pog
import server/photo
import server/premium
import server/sql
import server/web
import server/web/auth
import shared/shared_photo
import simplifile
import wisp
import youid/uuid

fn get_data(
  asset_id: String,
  db: pog.Connection,
  premium: Bool,
) -> Result(sql.PhotoFindDataByAssetIdRow, Nil) {
  use id <- result.try(uuid.from_string(asset_id))
  use res <- result.try(
    sql.photo_find_data_by_asset_id(db, id, premium)
    |> result.replace_error(Nil),
  )
  use photo <- result.try(res.rows |> list.first)
  Ok(photo)
}

pub fn get_data_premium(
  request: wisp.Request,
  context: web.Context,
  asset_id: String,
) -> wisp.Response {
  use user <- auth.get_user_from_session(request, context.db)

  case get_data(asset_id, context.db, True) {
    Ok(photo) -> {
      let body = case user {
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
  request: wisp.Request,
  context: web.Context,
  asset_id: String,
) -> wisp.Response {
  case get_data(asset_id, context.db, False) {
    Ok(photo) -> {
      wisp.ok()
      |> wisp.set_header("content-type", "image/png")
      |> wisp.set_body(wisp.Bytes(photo.data |> bytes_tree.from_bit_array))
    }
    Error(_) -> wisp.not_found()
  }
}

pub fn get(
  request: wisp.Request,
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

    let tags = case sql.tags_list_by_photo(context.db, photo.id) {
      Ok(res) -> list.map(res.rows, fn(row) { row.tag })
      Error(_) -> []
    }

    let user_liked = case context.user {
      Some(viewer) ->
        case sql.user_liked_photo(context.db, viewer.id, photo.id) {
          Ok(res) -> result.is_ok(list.first(res.rows))
          Error(_) -> False
        }
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

  use form <- wisp.require_form(request)

  let upload_result = {
    let description =
      result.unwrap(list.key_find(form.values, "description"), "")
    let premium =
      result.unwrap(list.key_find(form.values, "premium"), "false") == "true"
    let private =
      result.unwrap(list.key_find(form.values, "private"), "false") == "true"
    let location = result.unwrap(list.key_find(form.values, "location"), "")
    let camera = result.unwrap(list.key_find(form.values, "camera"), "")

    let tags_str = result.unwrap(list.key_find(form.values, "tags"), "")
    let tags =
      string.split(tags_str, ",")
      |> list.map(string.trim)
      |> list.filter(fn(t) { t != "" })

    use photo_file <- result.try(
      list.key_find(form.files, "photo") |> result.replace_error(Nil),
    )
    use photo_data <- result.try(
      simplifile.read_bits(photo_file.path) |> result.replace_error(Nil),
    )

    use res <- result.try(
      sql.photo_create(
        context.db,
        description,
        user.id,
        photo_data,
        premium,
        private,
        location,
        camera,
      )
      |> result.replace_error(Nil),
    )
    use new_photo <- result.try(list.first(res.rows))

    use _ <- result.try(
      list.try_each(tags, fn(tag) {
        sql.photo_add_tag(context.db, tag, new_photo.id)
        |> result.replace_error(Nil)
      }),
    )

    Ok(Nil)
  }

  case upload_result {
    Ok(_) -> wisp.redirect("/?upload_successful")
    Error(_) -> wisp.bad_request("Upload failed")
  }
}
