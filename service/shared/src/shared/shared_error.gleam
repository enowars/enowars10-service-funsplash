pub type InvalidData

pub type UserNotFound

pub type InvalidCredentials

pub type Unauthorized

pub type UploadError {
  FileMissing
  FileReadError
  DatabaseError
  InvalidForm
}

pub fn upload_error_to_string(err: UploadError) -> String {
  case err {
    FileMissing -> "No photo file was selected."
    FileReadError -> "An error occurred while reading the uploaded file."
    DatabaseError -> "An internal database error occurred while saving."
    InvalidForm -> "The form data provided was invalid."
  }
}
