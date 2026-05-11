SELECT images.*
FROM images
JOIN images_tags ON images.id = images_tags.image_id
WHERE images_tags.tag = $1;
