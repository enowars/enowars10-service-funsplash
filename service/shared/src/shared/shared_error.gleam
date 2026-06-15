import gleam/dynamic/decode
import gleam/fetch
import gleam/int
import gleam/json

pub type AuthError {
  InvalidData
  UserNotFound
  InvalidCredentials
  Unauthorized
}

pub fn auth_error_to_json(auth_error: AuthError) -> json.Json {
  case auth_error {
    InvalidData -> json.string("invalid_data")
    UserNotFound -> json.string("user_not_found")
    InvalidCredentials -> json.string("invalid_credentials")
    Unauthorized -> json.string("unauthorized")
  }
}

pub fn auth_error_to_string(err: AuthError) -> String {
  case err {
    InvalidData -> "Invalid data"
    UserNotFound -> "User not found"
    InvalidCredentials -> "username or password wrong"
    Unauthorized -> "Unauthorized"
  }
}

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
