INSERT INTO photos (description, creator, data, privacy, location, camera, show_on_profile)
VALUES (nullif($1,''),
	$2,
	$3,
	$4,
	nullif($5,''),
	nullif($6,''),
	$7)
RETURNING id;
