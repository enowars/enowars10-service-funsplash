WITH new_like AS (
    INSERT INTO likes (user_id, photo_id)
    SELECT $1, id
    FROM photos
    WHERE public_id = $2
    ON CONFLICT (user_id, photo_id) DO NOTHING
    RETURNING photo_id
)
UPDATE photos
SET likes_count = likes_count + 1
FROM new_like
WHERE photos.id = new_like.photo_id;
