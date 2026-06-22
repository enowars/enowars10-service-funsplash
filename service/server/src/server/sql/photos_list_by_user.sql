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
    created_at,
    file_size
FROM photos
WHERE creator = $1
AND show_on_profile = $2;
