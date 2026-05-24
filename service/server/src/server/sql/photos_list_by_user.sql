SELECT
	id,
    public_id,
    asset_id,
    title,
    description,
    creator,
    premium,
    private,
    show_on_profile,
    location,
    camera,
    likes_count,
    views,
    downloads,
    created_at
FROM photos
WHERE creator = $1
AND show_on_profile = $2;
