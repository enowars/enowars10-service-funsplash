SELECT *
FROM images
WHERE id = $1
LIMIT 1;
