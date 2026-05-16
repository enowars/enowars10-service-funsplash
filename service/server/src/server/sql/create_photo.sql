INSERT INTO photos (description, creator, photo, premium, private, location, camera)
VALUES (nullif($1,''),
	$2,
	$3,
	$4,
	$5,
	nullif($6,''),
	nullif($7,''));
