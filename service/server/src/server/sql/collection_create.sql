INSERT INTO collections (name, public_id,description, creator, private)
VALUES ($1, $2, nullif($3, ''), $4, $5)
RETURNING *;
