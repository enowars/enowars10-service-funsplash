//// This module contains the code to run the sql queries defined in
//// `./src/server/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `create_photo` query
/// defined in `./src/server/sql/create_photo.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreatePhotoRow {
  CreatePhotoRow(id: Uuid)
}

/// Runs the `create_photo` query
/// defined in `./src/server/sql/create_photo.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_photo(
  db: pog.Connection,
  arg_1: String,
  arg_2: Uuid,
  arg_3: BitArray,
  arg_4: Bool,
  arg_5: Bool,
  arg_6: String,
  arg_7: String,
) -> Result(pog.Returned(CreatePhotoRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    decode.success(CreatePhotoRow(id:))
  }

  "INSERT INTO photos (description, creator, photo, premium, private, location, camera)
VALUES (nullif($1,''),
	$2,
	$3,
	$4,
	$5,
	nullif($6,''),
	nullif($7,''))
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
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `create_photo_tag` query
/// defined in `./src/server/sql/create_photo_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_photo_tag(
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

/// A row you get from running the `create_user` query
/// defined in `./src/server/sql/create_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateUserRow {
  CreateUserRow(id: Uuid, username: String)
}

/// Runs the `create_user` query
/// defined in `./src/server/sql/create_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_user(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
) -> Result(pog.Returned(CreateUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use username <- decode.field(1, decode.string)
    decode.success(CreateUserRow(id:, username:))
  }

  "INSERT INTO users (username, first_name, last_name, password)
VALUES ($1,
	$2,
       	nullif($3,''),
	$4
)
RETURNING id, username;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `find_photo_by_id` query
/// defined in `./src/server/sql/find_photo_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindPhotoByIdRow {
  FindPhotoByIdRow(
    id: Uuid,
    description: Option(String),
    title: Option(String),
    creator: Uuid,
    photo: BitArray,
    premium: Bool,
    private: Bool,
    show_on_profile: Bool,
    location: Option(String),
    camera: Option(String),
    likes_count: Int,
    views: Int,
    downloads: Int,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `find_photo_by_id` query
/// defined in `./src/server/sql/find_photo_by_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_photo_by_id(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(FindPhotoByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.optional(decode.string))
    use title <- decode.field(2, decode.optional(decode.string))
    use creator <- decode.field(3, uuid_decoder())
    use photo <- decode.field(4, decode.bit_array)
    use premium <- decode.field(5, decode.bool)
    use private <- decode.field(6, decode.bool)
    use show_on_profile <- decode.field(7, decode.bool)
    use location <- decode.field(8, decode.optional(decode.string))
    use camera <- decode.field(9, decode.optional(decode.string))
    use likes_count <- decode.field(10, decode.int)
    use views <- decode.field(11, decode.int)
    use downloads <- decode.field(12, decode.int)
    use created_at <- decode.field(13, pog.timestamp_decoder())
    use updated_at <- decode.field(14, pog.timestamp_decoder())
    decode.success(FindPhotoByIdRow(
      id:,
      description:,
      title:,
      creator:,
      photo:,
      premium:,
      private:,
      show_on_profile:,
      location:,
      camera:,
      likes_count:,
      views:,
      downloads:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT *
FROM photos
WHERE id = $1
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `find_user_by_name` query
/// defined in `./src/server/sql/find_user_by_name.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindUserByNameRow {
  FindUserByNameRow(
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

/// Runs the `find_user_by_name` query
/// defined in `./src/server/sql/find_user_by_name.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_user_by_name(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(FindUserByNameRow), pog.QueryError) {
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
    decode.success(FindUserByNameRow(
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
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_photos_by_tag` query
/// defined in `./src/server/sql/list_photos_by_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListPhotosByTagRow {
  ListPhotosByTagRow(
    id: Uuid,
    description: Option(String),
    title: Option(String),
    creator: Uuid,
    photo: BitArray,
    premium: Bool,
    private: Bool,
    show_on_profile: Bool,
    location: Option(String),
    camera: Option(String),
    likes_count: Int,
    views: Int,
    downloads: Int,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `list_photos_by_tag` query
/// defined in `./src/server/sql/list_photos_by_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_photos_by_tag(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(ListPhotosByTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.optional(decode.string))
    use title <- decode.field(2, decode.optional(decode.string))
    use creator <- decode.field(3, uuid_decoder())
    use photo <- decode.field(4, decode.bit_array)
    use premium <- decode.field(5, decode.bool)
    use private <- decode.field(6, decode.bool)
    use show_on_profile <- decode.field(7, decode.bool)
    use location <- decode.field(8, decode.optional(decode.string))
    use camera <- decode.field(9, decode.optional(decode.string))
    use likes_count <- decode.field(10, decode.int)
    use views <- decode.field(11, decode.int)
    use downloads <- decode.field(12, decode.int)
    use created_at <- decode.field(13, pog.timestamp_decoder())
    use updated_at <- decode.field(14, pog.timestamp_decoder())
    decode.success(ListPhotosByTagRow(
      id:,
      description:,
      title:,
      creator:,
      photo:,
      premium:,
      private:,
      show_on_profile:,
      location:,
      camera:,
      likes_count:,
      views:,
      downloads:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT photos.*
FROM photos
JOIN photos_tags ON photos.id = photos_tags.photo_id
WHERE photos_tags.tag = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_photos_by_user` query
/// defined in `./src/server/sql/list_photos_by_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListPhotosByUserRow {
  ListPhotosByUserRow(
    id: Uuid,
    description: Option(String),
    title: Option(String),
    creator: Uuid,
    photo: BitArray,
    premium: Bool,
    private: Bool,
    show_on_profile: Bool,
    location: Option(String),
    camera: Option(String),
    likes_count: Int,
    views: Int,
    downloads: Int,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `list_photos_by_user` query
/// defined in `./src/server/sql/list_photos_by_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_photos_by_user(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Bool,
  arg_3: Bool,
) -> Result(pog.Returned(ListPhotosByUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.optional(decode.string))
    use title <- decode.field(2, decode.optional(decode.string))
    use creator <- decode.field(3, uuid_decoder())
    use photo <- decode.field(4, decode.bit_array)
    use premium <- decode.field(5, decode.bool)
    use private <- decode.field(6, decode.bool)
    use show_on_profile <- decode.field(7, decode.bool)
    use location <- decode.field(8, decode.optional(decode.string))
    use camera <- decode.field(9, decode.optional(decode.string))
    use likes_count <- decode.field(10, decode.int)
    use views <- decode.field(11, decode.int)
    use downloads <- decode.field(12, decode.int)
    use created_at <- decode.field(13, pog.timestamp_decoder())
    use updated_at <- decode.field(14, pog.timestamp_decoder())
    decode.success(ListPhotosByUserRow(
      id:,
      description:,
      title:,
      creator:,
      photo:,
      premium:,
      private:,
      show_on_profile:,
      location:,
      camera:,
      likes_count:,
      views:,
      downloads:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT *
FROM photos
WHERE creator = $1
AND private = $2
AND premium = $3;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.bool(arg_2))
  |> pog.parameter(pog.bool(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_tags_by_photo` query
/// defined in `./src/server/sql/list_tags_by_photo.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListTagsByPhotoRow {
  ListTagsByPhotoRow(tag: String)
}

/// Runs the `list_tags_by_photo` query
/// defined in `./src/server/sql/list_tags_by_photo.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_tags_by_photo(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(ListTagsByPhotoRow), pog.QueryError) {
  let decoder = {
    use tag <- decode.field(0, decode.string)
    decode.success(ListTagsByPhotoRow(tag:))
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

/// Runs the `remove_photo_tag` query
/// defined in `./src/server/sql/remove_photo_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn remove_photo_tag(
  db: pog.Connection,
  arg_1: String,
  arg_2: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "DELETE FROM photos_tags
WHERE tag = $1 AND photo_id = $2;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `user_likes_photo` query
/// defined in `./src/server/sql/user_likes_photo.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn user_likes_photo(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `user_unlikes_photo` query
/// defined in `./src/server/sql/user_unlikes_photo.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn user_unlikes_photo(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Uuid,
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
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
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
