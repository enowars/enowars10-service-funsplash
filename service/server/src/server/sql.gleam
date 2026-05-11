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

/// Runs the `create_image` query
/// defined in `./src/server/sql/create_image.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_image(
  db: pog.Connection,
  arg_1: String,
  arg_2: Uuid,
  arg_3: BitArray,
  arg_4: Bool,
  arg_5: Bool,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "INSERT INTO images (description, owner, image, premium, private)
VALUES ($1, $2, $3, $4, $5);
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(uuid.to_string(arg_2)))
  |> pog.parameter(pog.bytea(arg_3))
  |> pog.parameter(pog.bool(arg_4))
  |> pog.parameter(pog.bool(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `create_image_tag` query
/// defined in `./src/server/sql/create_image_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_image_tag(
  db: pog.Connection,
  arg_1: String,
  arg_2: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "WITH inserted_tag AS (
    INSERT INTO tags (tag) VALUES ($1) ON CONFLICT DO NOTHING
)
INSERT INTO images_tags (tag, image_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;
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
  CreateUserRow(id: Uuid, name: String)
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
) -> Result(pog.Returned(CreateUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    decode.success(CreateUserRow(id:, name:))
  }

  "INSERT INTO users (name, password)
VALUES ($1, $2)
RETURNING id, name;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `find_image` query
/// defined in `./src/server/sql/find_image.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindImageRow {
  FindImageRow(
    id: Uuid,
    description: Option(String),
    owner: Uuid,
    image: BitArray,
    premium: Bool,
    private: Bool,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `find_image` query
/// defined in `./src/server/sql/find_image.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_image(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(FindImageRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.optional(decode.string))
    use owner <- decode.field(2, uuid_decoder())
    use image <- decode.field(3, decode.bit_array)
    use premium <- decode.field(4, decode.bool)
    use private <- decode.field(5, decode.bool)
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())
    decode.success(FindImageRow(
      id:,
      description:,
      owner:,
      image:,
      premium:,
      private:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT *
FROM images
WHERE id = $1
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `find_user` query
/// defined in `./src/server/sql/find_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FindUserRow {
  FindUserRow(id: Uuid, name: String, password: String)
}

/// Runs the `find_user` query
/// defined in `./src/server/sql/find_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn find_user(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(FindUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use name <- decode.field(1, decode.string)
    use password <- decode.field(2, decode.string)
    decode.success(FindUserRow(id:, name:, password:))
  }

  "SELECT id, name, password
FROM users
WHERE name = $1
LIMIT 1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_images_by_tag` query
/// defined in `./src/server/sql/list_images_by_tag.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListImagesByTagRow {
  ListImagesByTagRow(
    id: Uuid,
    description: Option(String),
    owner: Uuid,
    image: BitArray,
    premium: Bool,
    private: Bool,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `list_images_by_tag` query
/// defined in `./src/server/sql/list_images_by_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_images_by_tag(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(ListImagesByTagRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.optional(decode.string))
    use owner <- decode.field(2, uuid_decoder())
    use image <- decode.field(3, decode.bit_array)
    use premium <- decode.field(4, decode.bool)
    use private <- decode.field(5, decode.bool)
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())
    decode.success(ListImagesByTagRow(
      id:,
      description:,
      owner:,
      image:,
      premium:,
      private:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT images.*
FROM images
JOIN images_tags ON images.id = images_tags.image_id
WHERE images_tags.tag = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_images_by_user` query
/// defined in `./src/server/sql/list_images_by_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListImagesByUserRow {
  ListImagesByUserRow(
    id: Uuid,
    description: Option(String),
    owner: Uuid,
    image: BitArray,
    premium: Bool,
    private: Bool,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `list_images_by_user` query
/// defined in `./src/server/sql/list_images_by_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_images_by_user(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: Bool,
  arg_3: Bool,
) -> Result(pog.Returned(ListImagesByUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.optional(decode.string))
    use owner <- decode.field(2, uuid_decoder())
    use image <- decode.field(3, decode.bit_array)
    use premium <- decode.field(4, decode.bool)
    use private <- decode.field(5, decode.bool)
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())
    decode.success(ListImagesByUserRow(
      id:,
      description:,
      owner:,
      image:,
      premium:,
      private:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT *
FROM images
WHERE owner = $1
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

/// A row you get from running the `list_tags_by_image` query
/// defined in `./src/server/sql/list_tags_by_image.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListTagsByImageRow {
  ListTagsByImageRow(tag: String)
}

/// Runs the `list_tags_by_image` query
/// defined in `./src/server/sql/list_tags_by_image.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_tags_by_image(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(ListTagsByImageRow), pog.QueryError) {
  let decoder = {
    use tag <- decode.field(0, decode.string)
    decode.success(ListTagsByImageRow(tag:))
  }

  "SELECT tag
FROM images_tags
WHERE image_id = $1;
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `remove_image_tag` query
/// defined in `./src/server/sql/remove_image_tag.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn remove_image_tag(
  db: pog.Connection,
  arg_1: String,
  arg_2: Uuid,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "DELETE FROM images_tags
WHERE tag = $1 AND image_id = $2;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
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
