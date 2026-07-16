INSERT INTO collections (name, description, creator, private)
VALUES ($1, nullif($2, ''), $3, $4)
RETURNING *;
