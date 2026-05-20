import gleam/bytes_tree
import gleam/http
import gleam/list
import gleam/result
import gleam/string
import server/sql
import server/web
import server/web/auth
import simplifile
import wisp
import youid/uuid

pub type Photo =
  sql.FindPhotoByIdRow

pub fn get(
  request: wisp.Request,
  context: web.Context,
  photo: String,
) -> wisp.Response {
  case request.method {
    http.Get -> get_photo(request, context, photo)
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn get_photo(
  request: wisp.Request,
  context: web.Context,
  photo: String,
) -> wisp.Response {
  let photo_result = {
    use id <- result.try(uuid.from_string(photo) |> result.replace_error(Nil))
    use res <- result.try(
      sql.find_photo_by_id(context.db, id) |> result.replace_error(Nil),
    )
    use row <- result.try(list.first(res.rows))
    Ok(row)
  }
  // FIXME: check private and premium
  case photo_result {
    Ok(row) -> {
      wisp.ok()
      |> wisp.set_header("content-type", "image/png")
      |> wisp.set_body(wisp.Bytes(bytes_tree.from_bit_array(row.photo)))
    }
    Error(_) -> wisp.not_found()
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
      sql.create_photo(
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
        sql.create_photo_tag(context.db, tag, new_photo.id)
        |> result.replace_error(Nil)
      }),
    )

    Ok(Nil)
  }

  case upload_result {
    Ok(_) -> wisp.redirect("/")
    Error(_) -> wisp.bad_request("Upload failed")
  }
}
