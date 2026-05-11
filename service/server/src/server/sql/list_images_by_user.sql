SELECT *
FROM images
WHERE owner = $1
AND private = $2
AND premium = $3;
