SELECT *
FROM photos
WHERE asset_id = $1
AND premium = $2
LIMIT 1;
