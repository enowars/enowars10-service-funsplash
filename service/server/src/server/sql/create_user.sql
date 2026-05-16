INSERT INTO users (username, first_name, last_name, password)
VALUES ($1,
	$2,
       	nullif($3,''),
	$4
)
RETURNING id, username;
