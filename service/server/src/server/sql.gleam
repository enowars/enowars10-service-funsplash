//// This module contains the code to run the sql queries defined in
//// `./src/server/sql`.
//// > 🐿️ This module was generated automatically using v4.7.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// Runs the `photo_add_tag` query
/// defined in `./src/server/sql/photo_add_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photo_add_tag(
  db: pog.Connection,
  arg_1: String,
  arg_2: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "WITH inserted_tag AS (
    INSERT INTO tags (tag) VALUES ($1) ON CONFLICT DO NOTHING
)
INSERT INTO photos_tags (tag, photo_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `photo_create` query
/// defined in `./src/server/sql/photo_create.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PhotoCreateRow {
  PhotoCreateRow(id: Uuid)
}

/// Runs the `photo_create` query
/// defined in `./src/server/sql/photo_create.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photo_create(
  db: pog.Connection,
  arg_1: String,
  arg_2: Uuid,
  arg_3: BitArray,
  arg_4: Bool,
  arg_5: Bool,
  arg_6: String,
  arg_7: String,
  arg_8: Bool,
) -> Result(pog.Returned(PhotoCreateRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(PhotoCreateRow(id:))
  }

  "INSERT INTO photos (description, creator, data, premium, private, location, camera, show_on_profile)
VALUES (nullif($1,''),
	$2,
	$3,
	$4,
	$5,
	nullif($6,''),
	nullif($7,''),
	$8)
RETURNING id;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.bytea(arg_3))
  |> pog.parameter(pog.bool(arg_4))
  |> pog.parameter(pog.bool(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.bool(arg_8))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `photo_find_by_public_id` query
/// defined in `./src/server/sql/photo_find_by_public_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PhotoFindByPublicIdRow {
  PhotoFindByPublicIdRow(
    id: Uuid,
    public_id: String,
    asset_id: Uuid,
    description: Option(String),
    title: Option(String),
    creator: Uuid,
    data: BitArray,
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

/// Runs the `photo_find_by_public_id` query
/// defined in `./src/server/sql/photo_find_by_public_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photo_find_by_public_id(
  db: pog.Connection,
  public_id: String,
) -> Result(pog.Returned(PhotoFindByPublicIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use public_id <- decode.field(1, decode.string)
    use asset_id <- decode.field(2, uuid_decoder())
    use description <- decode.field(3, decode.optional(decode.string))
    use title <- decode.field(4, decode.optional(decode.string))
    use creator <- decode.field(5, uuid_decoder())
    use data <- decode.field(6, decode.bit_array)
    use premium <- decode.field(7, decode.bool)
    use private <- decode.field(8, decode.bool)
    use show_on_profile <- decode.field(9, decode.bool)
    use location <- decode.field(10, decode.optional(decode.string))
    use camera <- decode.field(11, decode.optional(decode.string))
    use likes_count <- decode.field(12, decode.int)
    use views <- decode.field(13, decode.int)
    use downloads <- decode.field(14, decode.int)
    use created_at <- decode.field(15, pog.timestamp_decoder())
    decode.success(PhotoFindByPublicIdRow(
      id:,
      public_id:,
      asset_id:,
      description:,
      title:,
      creator:,
      data:,
      premium:,
      private:,
      show_on_profile:,
      location:,
      camera:,
      likes_count:,
      views:,
      downloads:,
      created_at:,
    ))
  }

  "SELECT *
FROM photos
WHERE public_id = $1
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(public_id))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `photo_find_data_by_asset_id` query
/// defined in `./src/server/sql/photo_find_data_by_asset_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PhotoFindDataByAssetIdRow {
  PhotoFindDataByAssetIdRow(
    id: Uuid,
    public_id: String,
    asset_id: Uuid,
    description: Option(String),
    title: Option(String),
    creator: Uuid,
    data: BitArray,
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

/// Runs the `photo_find_data_by_asset_id` query
/// defined in `./src/server/sql/photo_find_data_by_asset_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photo_find_data_by_asset_id(
  db: pog.Connection,
  asset_id: Uuid,
  premium: Bool,
) -> Result(pog.Returned(PhotoFindDataByAssetIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use public_id <- decode.field(1, decode.string)
    use asset_id <- decode.field(2, uuid_decoder())
    use description <- decode.field(3, decode.optional(decode.string))
    use title <- decode.field(4, decode.optional(decode.string))
    use creator <- decode.field(5, uuid_decoder())
    use data <- decode.field(6, decode.bit_array)
    use premium <- decode.field(7, decode.bool)
    use private <- decode.field(8, decode.bool)
    use show_on_profile <- decode.field(9, decode.bool)
    use location <- decode.field(10, decode.optional(decode.string))
    use camera <- decode.field(11, decode.optional(decode.string))
    use likes_count <- decode.field(12, decode.int)
    use views <- decode.field(13, decode.int)
    use downloads <- decode.field(14, decode.int)
    use created_at <- decode.field(15, pog.timestamp_decoder())
    decode.success(PhotoFindDataByAssetIdRow(
      id:,
      public_id:,
      asset_id:,
      description:,
      title:,
      creator:,
      data:,
      premium:,
      private:,
      show_on_profile:,
      location:,
      camera:,
      likes_count:,
      views:,
      downloads:,
      created_at:,
    ))
  }

  "SELECT *
FROM photos
WHERE asset_id = $1
AND premium = $2
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(asset_id)))
  |> pog.parameter(pog.bool(premium))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `photo_find_meta_by_public_id` query
/// defined in `./src/server/sql/photo_find_meta_by_public_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PhotoFindMetaByPublicIdRow {
  PhotoFindMetaByPublicIdRow(
    id: Uuid,
    public_id: String,
    asset_id: Uuid,
    title: Option(String),
    description: Option(String),
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

/// Runs the `photo_find_meta_by_public_id` query
/// defined in `./src/server/sql/photo_find_meta_by_public_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photo_find_meta_by_public_id(
  db: pog.Connection,
  public_id: String,
) -> Result(pog.Returned(PhotoFindMetaByPublicIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use public_id <- decode.field(1, decode.string)
    use asset_id <- decode.field(2, uuid_decoder())
    use title <- decode.field(3, decode.optional(decode.string))
    use description <- decode.field(4, decode.optional(decode.string))
    use creator <- decode.field(5, uuid_decoder())
    use premium <- decode.field(6, decode.bool)
    use private <- decode.field(7, decode.bool)
    use show_on_profile <- decode.field(8, decode.bool)
    use location <- decode.field(9, decode.optional(decode.string))
    use camera <- decode.field(10, decode.optional(decode.string))
    use likes_count <- decode.field(11, decode.int)
    use views <- decode.field(12, decode.int)
    use downloads <- decode.field(13, decode.int)
    use created_at <- decode.field(14, pog.timestamp_decoder())
    decode.success(PhotoFindMetaByPublicIdRow(
      id:,
      public_id:,
      asset_id:,
      title:,
      description:,
      creator:,
      premium:,
      private:,
      show_on_profile:,
      location:,
      camera:,
      likes_count:,
      views:,
      downloads:,
      created_at:,
    ))
  }

  "SELECT
    id,
    public_id,
    asset_id,
    title,
    description,
    creator,
    premium,
    private,
    show_on_profile,
    location,
    camera,
    likes_count,
    views,
    downloads,
    created_at
FROM photos
WHERE public_id = $1
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(public_id))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `photo_remove_tag` query
/// defined in `./src/server/sql/photo_remove_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photo_remove_tag(
  db: pog.Connection,
  tag: String,
  arg_2: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "DELETE FROM photos_tags
WHERE tag = $1 AND photo_id = $2;
"
  |> pog.query
  |> pog.parameter(pog.text(tag))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `photos_list_by_tag` query
/// defined in `./src/server/sql/photos_list_by_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PhotosListByTagRow {
  PhotosListByTagRow(public_id: String)
}

/// Runs the `photos_list_by_tag` query
/// defined in `./src/server/sql/photos_list_by_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photos_list_by_tag(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(PhotosListByTagRow), pog.QueryError) {
  let decoder = {
    use public_id <- decode.field(0, decode.string)
    decode.success(PhotosListByTagRow(public_id:))
  }

  "SELECT photos.public_id
FROM photos
JOIN photos_tags ON photos.id = photos_tags.photo_id
WHERE photos_tags.tag = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `photos_list_by_user` query
/// defined in `./src/server/sql/photos_list_by_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PhotosListByUserRow {
  PhotosListByUserRow(
    id: Uuid,
    public_id: String,
    asset_id: Uuid,
    title: Option(String),
    description: Option(String),
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

/// Runs the `photos_list_by_user` query
/// defined in `./src/server/sql/photos_list_by_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photos_list_by_user(
  db: pog.Connection,
  creator: Uuid,
  arg_2: Bool,
) -> Result(pog.Returned(PhotosListByUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use public_id <- decode.field(1, decode.string)
    use asset_id <- decode.field(2, uuid_decoder())
    use title <- decode.field(3, decode.optional(decode.string))
    use description <- decode.field(4, decode.optional(decode.string))
    use creator <- decode.field(5, uuid_decoder())
    use premium <- decode.field(6, decode.bool)
    use private <- decode.field(7, decode.bool)
    use show_on_profile <- decode.field(8, decode.bool)
    use location <- decode.field(9, decode.optional(decode.string))
    use camera <- decode.field(10, decode.optional(decode.string))
    use likes_count <- decode.field(11, decode.int)
    use views <- decode.field(12, decode.int)
    use downloads <- decode.field(13, decode.int)
    use created_at <- decode.field(14, pog.timestamp_decoder())
    decode.success(PhotosListByUserRow(
      id:,
      public_id:,
      asset_id:,
      title:,
      description:,
      creator:,
      premium:,
      private:,
      show_on_profile:,
      location:,
      camera:,
      likes_count:,
      views:,
      downloads:,
      created_at:,
    ))
  }

  "SELECT
	id,
    public_id,
    asset_id,
    title,
    description,
    creator,
    premium,
    private,
    show_on_profile,
    location,
    camera,
    likes_count,
    views,
    downloads,
    created_at
FROM photos
WHERE creator = $1
AND show_on_profile = $2;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(creator)))
  |> pog.parameter(pog.bool(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `photos_list_by_user_cursor_date` query
/// defined in `./src/server/sql/photos_list_by_user_cursor_date.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PhotosListByUserCursorDateRow {
  PhotosListByUserCursorDateRow(
    public_id: String,
    asset_id: Uuid,
    title: Option(String),
    description: Option(String),
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

/// Runs the `photos_list_by_user_cursor_date` query
/// defined in `./src/server/sql/photos_list_by_user_cursor_date.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn photos_list_by_user_cursor_date(
  db: pog.Connection,
  creator: Uuid,
  show_on_profile: Bool,
  arg_3: Timestamp,
) -> Result(pog.Returned(PhotosListByUserCursorDateRow), pog.QueryError) {
  let decoder = {
    use public_id <- decode.field(0, decode.string)
    use asset_id <- decode.field(1, uuid_decoder())
    use title <- decode.field(2, decode.optional(decode.string))
    use description <- decode.field(3, decode.optional(decode.string))
    use creator <- decode.field(4, uuid_decoder())
    use premium <- decode.field(5, decode.bool)
    use private <- decode.field(6, decode.bool)
    use show_on_profile <- decode.field(7, decode.bool)
    use location <- decode.field(8, decode.optional(decode.string))
    use camera <- decode.field(9, decode.optional(decode.string))
    use likes_count <- decode.field(10, decode.int)
    use views <- decode.field(11, decode.int)
    use downloads <- decode.field(12, decode.int)
    use created_at <- decode.field(13, pog.timestamp_decoder())
    decode.success(PhotosListByUserCursorDateRow(
      public_id:,
      asset_id:,
      title:,
      description:,
      creator:,
      premium:,
      private:,
      show_on_profile:,
      location:,
      camera:,
      likes_count:,
      views:,
      downloads:,
      created_at:,
    ))
  }

  "SELECT 
    public_id,
    asset_id,
    title,
    description,
    creator,
    premium,
    private,
    show_on_profile,
    location,
    camera,
    likes_count,
    views,
    downloads,
    created_at
FROM photos
WHERE creator = $1 
  AND show_on_profile = $2
  AND created_at < $3 -- $3 is the timestamp of the last photo they saw
ORDER BY created_at DESC
LIMIT 50;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(creator)))
  |> pog.parameter(pog.bool(show_on_profile))
  |> pog.parameter(pog.timestamp(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `tags_list_by_photo` query
/// defined in `./src/server/sql/tags_list_by_photo.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type TagsListByPhotoRow {
  TagsListByPhotoRow(tag: String)
}

/// Runs the `tags_list_by_photo` query
/// defined in `./src/server/sql/tags_list_by_photo.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn tags_list_by_photo(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(TagsListByPhotoRow), pog.QueryError) {
  let decoder = {
    use tag <- decode.field(0, decode.string)
    decode.success(TagsListByPhotoRow(tag:))
  }

  "SELECT tag
FROM photos_tags
WHERE photo_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `user_create` query
/// defined in `./src/server/sql/user_create.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UserCreateRow {
  UserCreateRow(id: Uuid, username: String)
}

/// Runs the `user_create` query
/// defined in `./src/server/sql/user_create.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn user_create(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: Bool,
) -> Result(pog.Returned(UserCreateRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use username <- decode.field(1, decode.string)
    decode.success(UserCreateRow(id:, username:))
  }

  "INSERT INTO users (username, first_name, last_name, password, bio, available_for_hire)
VALUES ($1,
	$2,
       	nullif($3,''),
	$4,
	nullif($5,''),
	$6
)
RETURNING id, username;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.bool(arg_6))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `user_find_by_id` query
/// defined in `./src/server/sql/user_find_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UserFindByIdRow {
  UserFindByIdRow(
    id: Uuid,
    username: String,
    first_name: String,
    last_name: Option(String),
    bio: Option(String),
    available_for_hire: Bool,
    premium: Bool,
    password: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `user_find_by_id` query
/// defined in `./src/server/sql/user_find_by_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn user_find_by_id(
  db: pog.Connection,
  id: Uuid,
) -> Result(pog.Returned(UserFindByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use username <- decode.field(1, decode.string)
    use first_name <- decode.field(2, decode.string)
    use last_name <- decode.field(3, decode.optional(decode.string))
    use bio <- decode.field(4, decode.optional(decode.string))
    use available_for_hire <- decode.field(5, decode.bool)
    use premium <- decode.field(6, decode.bool)
    use password <- decode.field(7, decode.string)
    use created_at <- decode.field(8, pog.timestamp_decoder())
    use updated_at <- decode.field(9, pog.timestamp_decoder())
    decode.success(UserFindByIdRow(
      id:,
      username:,
      first_name:,
      last_name:,
      bio:,
      available_for_hire:,
      premium:,
      password:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT *
FROM users
WHERE id=$1
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `user_find_by_name` query
/// defined in `./src/server/sql/user_find_by_name.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UserFindByNameRow {
  UserFindByNameRow(
    id: Uuid,
    username: String,
    first_name: String,
    last_name: Option(String),
    bio: Option(String),
    available_for_hire: Bool,
    premium: Bool,
    password: String,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `user_find_by_name` query
/// defined in `./src/server/sql/user_find_by_name.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn user_find_by_name(
  db: pog.Connection,
  username: String,
) -> Result(pog.Returned(UserFindByNameRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use username <- decode.field(1, decode.string)
    use first_name <- decode.field(2, decode.string)
    use last_name <- decode.field(3, decode.optional(decode.string))
    use bio <- decode.field(4, decode.optional(decode.string))
    use available_for_hire <- decode.field(5, decode.bool)
    use premium <- decode.field(6, decode.bool)
    use password <- decode.field(7, decode.string)
    use created_at <- decode.field(8, pog.timestamp_decoder())
    use updated_at <- decode.field(9, pog.timestamp_decoder())
    decode.success(UserFindByNameRow(
      id:,
      username:,
      first_name:,
      last_name:,
      bio:,
      available_for_hire:,
      premium:,
      password:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT *
FROM users
WHERE username = $1
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(username))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `user_liked_photo` query
/// defined in `./src/server/sql/user_liked_photo.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.7.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UserLikedPhotoRow {
  UserLikedPhotoRow(user_liked: Bool)
}

/// Runs the `user_liked_photo` query
/// defined in `./src/server/sql/user_liked_photo.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn user_liked_photo(
  db: pog.Connection,
  user_id: Uuid,
  arg_2: Uuid,
) -> Result(pog.Returned(UserLikedPhotoRow), pog.QueryError) {
  let decoder = {
    use user_liked <- decode.field(0, decode.bool)
    decode.success(UserLikedPhotoRow(user_liked:))
  }

  "SELECT true AS user_liked
FROM likes
WHERE user_id = $1 
AND photo_id = $2;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(user_id)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `user_likes_photo` query
/// defined in `./src/server/sql/user_likes_photo.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn user_likes_photo(
  db: pog.Connection,
  arg_1: Uuid,
  id: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "WITH inserted_like AS (
    INSERT INTO likes (user_id, photo_id)
    VALUES ($1, $2)
    ON CONFLICT (user_id, photo_id) DO NOTHING
    RETURNING *
)
UPDATE photos
SET likes_count = likes_count + 1
WHERE id = $2
  AND EXISTS (SELECT 1 FROM inserted_like);
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `user_unlikes_photo` query
/// defined in `./src/server/sql/user_unlikes_photo.sql`.
///
/// > 🐿️ This function was generated automatically using v4.7.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn user_unlikes_photo(
  db: pog.Connection,
  user_id: Uuid,
  photo_id: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "WITH deleted_like AS (
DELETE FROM likes 
WHERE user_id = $1 AND photo_id = $2
RETURNING *
)
UPDATE photos
SET likes_count = likes_count - 1 
WHERE id = $2 
AND EXISTS (SELECT 1 FROM deleted_like);
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(user_id)))
  |> pog.parameter(pog.text(uuid.to_string(photo_id)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Encoding/decoding utils -------------------------------------------------

/// A decoder to decode `Uuid`s coming from a Postgres query.
///
fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "Uuid")
  }
}
