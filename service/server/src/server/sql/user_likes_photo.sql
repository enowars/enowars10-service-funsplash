WITH inserted_like AS (
    INSERT INTO likes (user_id, photo_id)
    VALUES ($1, $2)
    ON CONFLICT (user_id, photo_id) DO NOTHING
    RETURNING *
)
UPDATE photos
SET likes_count = likes_count + 1
WHERE id = $2
  AND EXISTS (SELECT 1 FROM inserted_like);
