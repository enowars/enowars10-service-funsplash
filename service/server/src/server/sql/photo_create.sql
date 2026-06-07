INSERT INTO photos (description, creator, data, premium, private, location, camera, show_on_profile)
VALUES (nullif($1,''),
	$2,
	$3,
	$4,
	$5,
	nullif($6,''),
	nullif($7,''),
	$8)
RETURNING id;
