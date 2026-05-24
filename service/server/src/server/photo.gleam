import gleam/bytes_tree
import gleam/http
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import server/sql
import server/web
import server/web/auth
import shared/shared_photo
import simplifile
import wisp
import youid/uuid.{type Uuid}

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
