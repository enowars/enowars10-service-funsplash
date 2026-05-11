SELECT id, name, password
FROM users
WHERE name = $1
LIMIT 1;
