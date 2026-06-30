SELECT username, first_name, last_name, bio, available_for_hire, premium
FROM users
WHERE username ILIKE $1 || '%' ORDER BY created_at ASC;
