import bravo/uset
import file_streams/file_stream
import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import mimetype
import pog
import server/sql
import server/user.{type User, User}
import shared/shared_photo
import shared/shared_privacy.{type Privacy, Premium, Private, Public}
import shared/shared_stats
import shared/shared_thumbnail
import shared/shared_upload
import simplifile
import utils
import youid/uuid.{type Uuid}

pub type Photo {
  Photo(
    id: Uuid,
    public_id: String,
    asset_id: Uuid,
    description: Option(String),
    creator: Uuid,
    privacy: Privacy,
    mimetype: shared_upload.MimeType,
    show_on_profile: Bool,
    location: Option(String),
    camera: Option(String),
    likes_count: Int,
    views: Int,
    downloads: Int,
    file_size: Int,
    created_at: Timestamp,
  )
}

pub fn get_data(
  _privacy: Privacy,
  asset_id: uuid.Uuid,
) -> Result(BitArray, Nil) {
  let fs_path = "/app/data/photos/" <> uuid.to_string(asset_id)
  case simplifile.read_bits(fs_path) {
    Ok(data) -> Ok(data)
    Error(_) -> Error(Nil)
  }
}

pub fn get_tags(db: pog.Connection, photo_id: Uuid) -> List(String) {
  case sql.tags_list_by_photo(db, photo_id) {
    Ok(res) -> list.map(res.rows, fn(row) { row.tag })
    Error(_) -> []
  }
}

pub fn get(db, public_id) -> Result(Photo, Nil) {
  use photo <- utils.db_limit_try(
    sql.photo_find_by_public_id(db, public_id)
      |> result.replace_error(Nil),
    Nil,
  )
  Ok(photo |> from_photo_find_by_public_id_row)
}

pub fn user_liked(
  db: pog.Connection,
  photo_id pid: Uuid,
  user_id uid: Uuid,
) -> Bool {
  case sql.user_liked_photo(db, uid, pid) {
    Ok(res) -> result.is_ok(list.first(res.rows))
    Error(_) -> False
  }
}

pub fn upload(
  photo p: shared_upload.Upload,
  db_connection db: pog.Connection,
  user_cache uc: user.UserCache,
) -> Result(Nil, shared_upload.Error) {
  let size = case p.data {
    shared_upload.InMemory(data:, mimetype: _) -> bit_array.byte_size(data)
    shared_upload.File(path: _, size:) -> size
  }

  use <- bool.guard(
    size > shared_upload.max_allowed_size,
    Error(shared_upload.ImageTooLarge(shared_upload.max_allowed_size)),
  )

  use user <- result.try(
    uset.lookup(uc, p.creator)
    |> result.replace_error(shared_upload.InternalError),
  )

  let new_used_quota = user.storage_quota_used + size
  use <- bool.guard(
    new_used_quota > user.storage_quota,
    Error(shared_upload.QuotaExceeded(user.storage_quota_used)),
  )

  let mimetype = case p.data {
    shared_upload.InMemory(data: _, mimetype:) -> mimetype
    shared_upload.File(path:, size: _) ->
      path |> detect_mimetype() |> result.unwrap(shared_upload.Other)
  }

  use new_photo <- utils.db_limit_try(
    sql.photo_create(
      db,
      p.description |> option.unwrap(""),
      p.creator,
      p.privacy |> privacy_to_sql,
      p.location |> option.unwrap(""),
      p.camera |> option.unwrap(""),
      p.show_on_profile,
      size,
      mimetype |> shared_mimetype_to_sql,
    ),
    shared_upload.InternalError,
  )

  let _ =
    uset.insert(uc, user.id, User(..user, storage_quota_used: new_used_quota))

  let fs_path = "/app/data/photos/" <> uuid.to_string(new_photo.asset_id)
  use _ <- result.try(
    case p.data {
      shared_upload.InMemory(data:, mimetype: _) ->
        simplifile.write_bits(fs_path, data)
      shared_upload.File(path:, size: _) -> simplifile.rename(path, fs_path)
    }
    |> result.replace_error(shared_upload.InternalError),
  )

  list.try_each(p.tags, fn(tag) {
    sql.photo_add_tag(db, tag, new_photo.id)
    |> result.replace_error(shared_upload.InternalError)
  })
}

fn detect_mimetype(path: String) -> Result(shared_upload.MimeType, Nil) {
  use stream <- result.try(
    file_stream.open_read(path) |> result.replace_error(Nil),
  )
  use top <- result.try(
    file_stream.read_bytes(stream, 32) |> result.replace_error(Nil),
  )
  mimetype.detect(top)
  |> mimetype_to_shared
  |> Ok()
}

// mappers

fn sql_to_shared_mimetype(mimetype: sql.Mimetype) -> shared_upload.MimeType {
  case mimetype {
    sql.Other -> shared_upload.Other
    sql.Webp -> shared_upload.Webp
    sql.Jpg -> shared_upload.Jpg
    sql.Png -> shared_upload.Png
  }
}

pub fn shared_mimetype_to_sql(
  mimetype: shared_upload.MimeType,
) -> sql.Mimetype {
  case mimetype {
    shared_upload.Png -> sql.Png
    shared_upload.Jpg -> sql.Jpg
    shared_upload.Webp -> sql.Webp
    shared_upload.Other -> sql.Other
  }
}

pub fn mimetype_to_shared(
  mimetype: mimetype.MimeType,
) -> shared_upload.MimeType {
  case mimetype.to_string(mimetype) {
    "image/png" -> shared_upload.Png
    "image/jpeg" -> shared_upload.Jpg
    "image/webp" -> shared_upload.Webp
    _ -> shared_upload.Other
  }
}

pub fn privacy_to_sql(priv: Privacy) -> sql.PhotoPrivacy {
  case priv {
    Public -> sql.Public
    Premium -> sql.Premium
    Private -> sql.Private
  }
}

fn sql_to_privacy(priv: sql.PhotoPrivacy) -> Privacy {
  case priv {
    sql.Public -> Public
    sql.Premium -> Premium
    sql.Private -> Private
  }
}

pub fn to_shared(
  photo: Photo,
  creator: String,
  tags: List(String),
  user_liked: Bool,
) -> shared_photo.Photo {
  shared_photo.Photo(
    thumbnail: to_shared_thumbnail(photo, creator, user_liked),
    description: photo.description,
    stats: to_shared_stats(photo),
    location: photo.location,
    camera: photo.camera,
    created_at: photo.created_at |> timestamp.to_unix_seconds,
    tags:,
  )
}

pub fn to_shared_stats(p: Photo) -> shared_stats.Stats {
  shared_stats.Stats(
    views: p.views,
    likes: p.likes_count,
    downloads: p.downloads,
  )
}

pub fn to_shared_thumbnail(
  p: Photo,
  creator: String,
  user_liked: Bool,
) -> shared_thumbnail.Thumbnail {
  shared_thumbnail.Thumbnail(
    public_id: p.public_id,
    asset_id: p.asset_id |> uuid.to_string,
    description: p.description,
    creator: creator,
    privacy: p.privacy,
    user_liked:,
    show_on_profile: p.show_on_profile,
  )
}

pub fn from_photo_find_by_public_id_row(
  p: sql.PhotoFindByPublicIdRow,
) -> Photo {
  Photo(
    id: p.id,
    public_id: p.public_id,
    asset_id: p.asset_id,
    description: p.description,
    creator: p.creator,
    privacy: p.privacy |> sql_to_privacy,
    show_on_profile: p.show_on_profile,
    mimetype: p.mimetype |> sql_to_shared_mimetype,
    location: p.location,
    camera: p.camera,
    likes_count: p.likes_count,
    views: p.views,
    downloads: p.downloads,
    created_at: p.created_at,
    file_size: p.file_size,
  )
}

pub fn from_photos_list_by_user_row(photo p: sql.PhotosListByUserRow) -> Photo {
  Photo(
    id: p.id,
    public_id: p.public_id,
    asset_id: p.asset_id,
    description: p.description,
    creator: p.creator,
    privacy: p.privacy |> sql_to_privacy,
    show_on_profile: p.show_on_profile,
    mimetype: p.mimetype |> sql_to_shared_mimetype,
    location: p.location,
    camera: p.camera,
    likes_count: p.likes_count,
    views: p.views,
    downloads: p.downloads,
    created_at: p.created_at,
    file_size: p.file_size,
  )
}

pub fn from_photos_list_by_owner_row(
  photo p: sql.PhotosListByOwnerRow,
) -> Photo {
  Photo(
    id: p.id,
    public_id: p.public_id,
    asset_id: p.asset_id,
    description: p.description,
    creator: p.creator,
    privacy: p.privacy |> sql_to_privacy,
    show_on_profile: p.show_on_profile,
    mimetype: p.mimetype |> sql_to_shared_mimetype,
    location: p.location,
    camera: p.camera,
    likes_count: p.likes_count,
    views: p.views,
    downloads: p.downloads,
    file_size: p.file_size,
    created_at: p.created_at,
  )
}
