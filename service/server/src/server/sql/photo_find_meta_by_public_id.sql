SELECT
    id,
    public_id,
    asset_id,
    description,
    creator,
    privacy,
    show_on_profile,
    location,
    camera,
    likes_count,
    views,
    downloads,
    created_at
FROM photos
WHERE public_id = $1
LIMIT 1;
