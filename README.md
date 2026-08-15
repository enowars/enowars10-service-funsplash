# funsplash

Share your images with the world, friends, paying members, hackers ,and the government.

## Overview

funsplash is a web application that allows users to:
- Share photos with different privacy levels (Public, Private, Premium)
- Organize photos into collections (public or private)
- Search for users and view their profiles
- Like photos
- Download uploaded images
- Censor premium images via a websocket API

## Services

The Docker container exposes the following services:

| Port(s) | Service   | Description                  |
|---------|-----------|------------------------------|
| `1337`  | funsplash | Main web application service |

## Endpoints

Endpoints are grouped by feature. Endpoints often require a valid session cookie for authentication.

### Search & info

| Method | Endpoint                            | Description                       |
|--------|-------------------------------------|-----------------------------------|
| `GET`  | `/napi/users/:username`             | Retrieve user profile information |
| `GET`  | `/napi/s/users/:username`           | Search for a user by prefix       |
| `GET`  | `/napi/users/:username/photos`      | List a user's uploaded photos     |
| `GET`  | `/napi/users/:username/collections` | List a user's collections         |

### Account & auth

| Method | Endpoint                 | Description                            |
|--------|--------------------------|----------------------------------------|
| `POST` | `/napi/join`             | Register a new user                    |
| `POST` | `/napi/login`            | Login to an existing account           |
| `POST` | `/napi/logout`           | Logout the current user                |
| `GET`  | `/napi/me`               | Fetch the currently authenticated user |
| `POST` | `/napi/account`          | Update account details                 |
| `POST` | `/napi/account/password` | Change account password                |

### Photos & likes

| Method   | Endpoint                  | Description                                               |
|----------|---------------------------|-----------------------------------------------------------|
| `POST`   | `/napi/upload`            | Upload a new photo                                        |
| `GET`    | `/napi/photos/:public_id` | View photo metadata                                       |
| `POST`   | `/napi/photos/:public_id` | Update photo details                                      |
| `DELETE` | `/napi/photos/:public_id` | Delete a photo                                            |
| `POST`   | `/napi/like/:public_id`   | Like a photo                                              |
| `DELETE` | `/napi/like/:public_id`   | Remove a like from a photo                                |
| `WS`     | `/napi/censor/:photo_id`  | Websocket endpoint to censor a photo using provided masks |

### Collections

| Method   | Endpoint                                 | Description                      |
|----------|------------------------------------------|----------------------------------|
| `POST`   | `/napi/collections`                      | Create a new collection          |
| `GET`    | `/napi/collections/:id`                  | View a collection                |
| `POST`   | `/napi/collections/:id`                  | Update collection details        |
| `DELETE` | `/napi/collections/:id`                  | Delete a collection              |
| `GET`    | `/napi/collections/:id/photos`           | Get photos inside a collection   |
| `POST`   | `/napi/collections/:id/photos/:photo_id` | Add a photo to a collection      |
| `DELETE` | `/napi/collections/:id/photos/:photo_id` | Remove a photo from a collection |

### Images

| Method | Endpoint                          | Description              |
|--------|-----------------------------------|--------------------------|
| `GET`  | `/images/photo-:asset_id`         | Download a public photo  |
| `GET`  | `/images/premium_photo-:asset_id` | Download a premium photo |
| `GET`  | `/images/private_photo-:asset_id` | Download a private photo |

## Flagstore 0

The checker registers a user and uploads a Premium photo (`privacy=Premium`) containing the flag encoded as a QR code in the image data. The attack info is the victim's username.

The flagstore can be exploited through a compression oracle (CRIME-like) on the `/napi/censor` websocket endpoint.

1. **Unrestricted Censor Access**: The `/napi/censor/:photo_id` websocket endpoint allows applying masks to images, including premium photos belonging to other users.
2. **Compression Oracle**: By sending various masks (e.g., blacking out everything except a specific pixel or region), the attacker receives the censored image back. The compressed size (zlib/deflate) of the resulting PNG varies based on the underlying hidden pixels.
3. **Pixel Reconstruction**: The attacker repeatedly censors different parts of the image and measures the response sizes. These size differences leak the colors of the underlying pixels.
4. **Flag Disclosure**: The attacker reconstructs the original QR code pixel by pixel and decodes it to retrieve the flag.

## Flagstore 1

The checker registers a user and uploads a Public photo containing the flag encoded as a QR code, but with `show_on_profile=False` so it remains hidden. The attack info is the victim's username.

The flagstore can be exploited through case-sensitivity issues during user lookup or caching.

1. **Spoofed User Registration**: The attacker creates a new account and updates their username to a randomly capitalized version of the victim's username (e.g., `viCtIm` for `victim`).
2. **Cache/DB Confusion**: The backend database or cache treats the capitalized username equivalently when routing or evaluating permissions.
3. **Hidden Photo Extraction**: The attacker requests the victim's profile using the spoofed casing. This bypasses the filter for `show_on_profile=False` or tricks the API into returning the victim's hidden photos as if the attacker owned them.
4. **Flag Disclosure**: The attacker downloads the hidden photo and decodes the QR code to extract the flag.

## Flagstore 2

The checker registers a user and creates a private collection. The flag is stored in the description of this private collection. The attack info is the victim's username.

The flagstore can be exploited through PRNG (Pseudo-Random Number Generator) state recovery.

1. **Predictable IDs**: The `public_id` assigned to new collections is generated using an insecure or predictable PRNG (e.g., an Erlang `rand` module with an extractable state).
2. **State Recovery**: The attacker creates a burst of their own collections to observe a sequence of generated `public_id`s. They then use an `escript` (Erlang script) to recover the internal state of the PRNG from these observed outputs.
3. **ID Prediction**: With the PRNG state recovered, the attacker predicts the `public_id` that was generated for the victim's private collection.
4. **Flag Disclosure**: Knowing the exact `public_id` of the victim's collection allows the attacker to query it directly (due to weak access controls) and read the description containing the flag.
