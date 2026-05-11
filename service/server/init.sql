CREATE EXTENSION IF NOT EXISTS citext;


CREATE TABLE users (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
name CITEXT NOT NULL UNIQUE,
password TEXT NOT NULL,
created_at TIMESTAMP NOT NULL DEFAULT now(),
updated_at TIMESTAMP NOT NULL DEFAULT now()
);


CREATE TABLE images (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
description TEXT,
owner UUID NOT NULL,
FOREIGN KEY (owner) REFERENCES users(id),
image BYTEA NOT NULL,
premium BOOLEAN NOT NULL,
private BOOLEAN NOT NULL,
created_at TIMESTAMP NOT NULL DEFAULT now(),
updated_at TIMESTAMP NOT NULL DEFAULT now()
);


CREATE TABLE tags (
tag CITEXT PRIMARY KEY
);


CREATE TABLE images_tags (
tag CITEXT,
image_id UUID,
PRIMARY KEY (tag, image_id),
FOREIGN KEY (image_id) REFERENCES images(id),
FOREIGN KEY (tag) REFERENCES tags(tag)
);
