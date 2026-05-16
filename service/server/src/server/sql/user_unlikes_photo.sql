WITH deleted_like AS (
DELETE FROM likes 
WHERE user_id = $1 AND photo_id = $2
RETURNING *
)
UPDATE photos
SET likes_count = likes_count - 1 
WHERE id = $2 
AND EXISTS (SELECT 1 FROM deleted_like);
