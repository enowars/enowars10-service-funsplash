import server/photo
import shared/shared_thumbnail
import youid/uuid

pub fn get() {
  todo
}

pub fn from_photo(photo: photo.Photo, creator: String, user_liked: Bool) {
  shared_thumbnail.Thumbnail(
    public_id: photo.public_id,
    asset_id: photo.asset_id |> uuid.to_string,
    description: photo.description,
    creator:,
    premium: photo.premium,
    private: photo.private,
    user_liked:,
    show_on_profile: photo.show_on_profile,
  )
}
