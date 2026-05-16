SELECT *
FROM photos
WHERE creator = $1
AND private = $2
AND premium = $3;
