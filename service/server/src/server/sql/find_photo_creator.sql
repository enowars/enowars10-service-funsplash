SELECT creator
FROM photos
WHERE id = $1
LIMIT 1;
