DELETE FROM images_tags
WHERE tag = $1 AND image_id = $2;
