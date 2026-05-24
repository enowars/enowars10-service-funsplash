CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

-- TODO: look at unsplash edit profile for more options
CREATE TABLE users (
id UUID PRIMARY KEY DEFAULT uuidv7(),
username CITEXT NOT NULL UNIQUE,
first_name TEXT NOT NULL,
last_name TEXT,
bio TEXT,
available_for_hire BOOLEAN NOT NULL DEFAULT false,
premium BOOLEAN NOT NULL DEFAULT false,
password TEXT NOT NULL,
created_at TIMESTAMP NOT NULL DEFAULT now(),
updated_at TIMESTAMP NOT NULL DEFAULT now()
);


CREATE TABLE photos (
id UUID PRIMARY KEY DEFAULT uuidv7(),
public_id VARCHAR(12) NOT NULL UNIQUE DEFAULT
	substring(translate(encode(gen_random_bytes(9), 'base64'), '+/', '-_'), 1, 11),
asset_id UUID NOT NULL UNIQUE DEFAULT uuidv7(),
description TEXT,
title CITEXT,
creator UUID NOT NULL,
	FOREIGN KEY (creator) REFERENCES users(id) ON DELETE CASCADE,
data BYTEA NOT NULL,		--TODO: move out and into seperate table or fs
premium BOOLEAN NOT NULL,
private BOOLEAN NOT NULL,
show_on_profile BOOLEAN NOT NULL DEFAULT true,
location TEXT,
camera TEXT,
likes_count INT NOT NULL DEFAULT 0,
views BIGINT NOT NULL DEFAULT 0,
downloads BIGINT NOT NULL DEFAULT 0,
created_at TIMESTAMP NOT NULL DEFAULT now()
);


CREATE TABLE tags (
tag CITEXT PRIMARY KEY
);


CREATE TABLE photos_tags (
tag CITEXT NOT NULL,
    	 FOREIGN KEY (tag) REFERENCES tags(tag),
photo_id UUID NOT NULL,
	 FOREIGN KEY (photo_id) REFERENCES photos(id) ON DELETE CASCADE,
PRIMARY KEY (tag, photo_id)
);


CREATE TABLE collections (
id UUID PRIMARY KEY DEFAULT uuidv7(),
name TEXT NOT NULL,
description TEXT,
creator UUID NOT NULL,
	FOREIGN KEY (creator) REFERENCES users(id) ON DELETE CASCADE,
private BOOLEAN NOT NULL
);

create table collections_photos (
photo_id UUID NOT NULL,
	 FOREIGN KEY (photo_id) REFERENCES photos(id) ON DELETE CASCADE,
collection_id UUID NOT NULL,
	 FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
PRIMARY KEY (photo_id, collection_id)
);

CREATE TABLE likes (
user_id UUID NOT NULL,
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
photo_id UUID NOT NULL,
	FOREIGN KEY (photo_id) REFERENCES photos(id) ON DELETE CASCADE,
PRIMARY KEY (user_id, photo_id)
);
