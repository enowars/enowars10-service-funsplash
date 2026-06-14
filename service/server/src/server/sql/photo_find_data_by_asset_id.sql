SELECT *
FROM photos
WHERE asset_id = $1
AND privacy = $2
LIMIT 1;
