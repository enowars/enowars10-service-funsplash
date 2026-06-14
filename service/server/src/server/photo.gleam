import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import pog
import server/sql
import shared/shared_photo
import shared/shared_privacy.{type Privacy, Premium, Private, Public}
import shared/shared_stats
import shared/shared_thumbnail
import shared/shared_upload
import youid/uuid.{type Uuid}

fn privacy_to_sql(priv: Privacy) -> sql.PhotoPrivacy {
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

pub type Photo {
  Photo(
    id: Uuid,
    public_id: String,
    asset_id: Uuid,
    description: Option(String),
    title: Option(String),
    creator: Uuid,
    privacy: Privacy,
    show_on_profile: Bool,
    location: Option(String),
    camera: Option(String),
    likes_count: Int,
    views: Int,
    downloads: Int,
    created_at: Timestamp,
  )
}

pub fn to_shared(
  photo: Photo,
  creator: String,
  tags: List(String),
  user_liked: Bool,
) -> shared_photo.Photo {
  shared_photo.Photo(
    thumbnail: to_shared_thumbnail(photo, creator, user_liked),
    stats: to_shared_stats(photo),
    title: photo.title,
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
    title: p.title,
    creator: p.creator,
    privacy: p.privacy |> sql_to_privacy,
    show_on_profile: p.show_on_profile,
    location: p.location,
    camera: p.camera,
    likes_count: p.likes_count,
    views: p.views,
    downloads: p.downloads,
    created_at: p.created_at,
  )
}

pub fn from_photos_list_by_user_row(p: sql.PhotosListByUserRow) -> Photo {
  Photo(
    id: p.id,
    public_id: p.public_id,
    asset_id: p.asset_id,
    description: p.description,
    title: p.title,
    creator: p.creator,
    privacy: p.privacy |> sql_to_privacy,
    show_on_profile: p.show_on_profile,
    location: p.location,
    camera: p.camera,
    likes_count: p.likes_count,
    views: p.views,
    downloads: p.downloads,
    created_at: p.created_at,
  )
}

pub fn get_data(
  asset_id: String,
  db: pog.Connection,
  privacy: Privacy,
) -> Result(sql.PhotoFindDataByAssetIdRow, Nil) {
  use id <- result.try(uuid.from_string(asset_id))
  use res <- result.try(
    sql.photo_find_data_by_asset_id(db, id, privacy |> privacy_to_sql)
    |> result.replace_error(Nil),
  )
  use photo <- result.try(res.rows |> list.first)
  Ok(photo)
}

pub fn get_tags(db: pog.Connection, photo_id: Uuid) -> List(String) {
  case sql.tags_list_by_photo(db, photo_id) {
    Ok(res) -> list.map(res.rows, fn(row) { row.tag })
    Error(_) -> []
  }
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

pub fn upload(photo p: shared_upload.Upload, db_connection db: pog.Connection) {
  use res <- result.try(
    sql.photo_create(
      db,
      p.description |> option.unwrap(""),
      p.creator,
      p.data,
      p.privacy |> privacy_to_sql,
      p.location |> option.unwrap(""),
      p.camera |> option.unwrap(""),
      p.show_on_profile,
    )
    |> result.replace_error(Nil),
  )

  use new_photo <- result.try(list.first(res.rows))

  list.try_each(p.tags, fn(tag) {
    sql.photo_add_tag(db, tag, new_photo.id)
    |> result.replace_error(Nil)
  })
}
