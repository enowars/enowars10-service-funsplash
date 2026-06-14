import gleam/dynamic/decode
import gleam/fetch
import gleam/int

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

pub type ApiError {
  InvalidUrl(url: String)
  UnexpectedStatus(status: Int)
  FetchError(fetch.FetchError)
  DecodeError(List(decode.DecodeError))
}

pub fn api_error_to_string(error: ApiError) -> String {
  case error {
    InvalidUrl(url) -> "Invalid URL: " <> url
    UnexpectedStatus(status) -> "Unexpected status: " <> int.to_string(status)
    FetchError(fetch.NetworkError(detail)) -> "Network error: " <> detail
    FetchError(fetch.UnableToReadBody) -> "Unable to read response body"
    FetchError(fetch.InvalidJsonBody) -> "Response is not valid JSON"
    DecodeError(_) -> "Failed to decode response"
  }
}
