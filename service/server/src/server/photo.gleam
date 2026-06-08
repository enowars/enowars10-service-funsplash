import gleam/bit_array
import gleam/bytes_tree
import gleam/http
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import pog
import server/sql
import server/web
import server/web/auth
import shared/shared_error
import shared/shared_photo
import simplifile
import wisp
import youid/uuid.{type Uuid}

pub type Upload {
  Upload(
    creator: Uuid,
    description: Option(String),
    premium: Bool,
    private: Bool,
    location: Option(String),
    camera: Option(String),
    show_on_profile: Bool,
    data: BitArray,
    tags: List(String),
  )
}

pub fn default_upload(creator: Uuid, data: BitArray) -> Upload {
  Upload(
    creator:,
    description: None,
    premium: False,
    private: False,
    location: None,
    camera: None,
    show_on_profile: True,
    data:,
    tags: [],
  )
}

pub type Photo {
  Photo(
    id: Uuid,
    public_id: String,
    asset_id: Uuid,
    description: Option(String),
    title: Option(String),
    creator: Uuid,
    premium: Bool,
    private: Bool,
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
    public_id: photo.public_id,
    asset_id: photo.asset_id |> uuid.to_string,
    description: photo.description,
    title: photo.title,
    creator:,
    premium: photo.premium,
    private: photo.private,
    show_on_profile: photo.show_on_profile,
    location: photo.location,
    camera: photo.camera,
    likes_count: photo.likes_count,
    views: photo.views,
    downloads: photo.downloads,
    created_at: photo.created_at |> timestamp.to_unix_seconds,
    //
    tags:,
    user_liked:,
  )
}

pub fn from_photo_find_by_public_id_row(p: sql.PhotoFindByPublicIdRow) -> Photo {
  Photo(
    id: p.id,
    public_id: p.public_id,
    asset_id: p.asset_id,
    description: p.description,
    title: p.title,
    creator: p.creator,
    premium: p.premium,
    private: p.private,
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
    premium: p.premium,
    private: p.private,
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

pub fn create(photo p: Upload, db_connection db: pog.Connection) {
  use res <- result.try(
    sql.photo_create(
      db,
      p.description |> option.unwrap(""),
      p.creator,
      p.data,
      p.premium,
      p.private,
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
