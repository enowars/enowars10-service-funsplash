WITH updated_user AS (
     UPDATE users
     SET storage_quota_used = storage_quota_used + $8
     WHERE id = $2
)
INSERT INTO photos (description, creator, data, privacy, location, camera, show_on_profile, file_size)
VALUES (nullif($1,''),
	$2,
	$3,
	$4,
	nullif($5,''),
	nullif($6,''),
	$7,
	$8)
RETURNING id;
