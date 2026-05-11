WITH inserted_tag AS (
    INSERT INTO tags (tag) VALUES ($1) ON CONFLICT DO NOTHING
)
INSERT INTO images_tags (tag, image_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;
