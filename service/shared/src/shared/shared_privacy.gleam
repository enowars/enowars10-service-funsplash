import gleam/dynamic/decode
import gleam/json

pub type Privacy {
  Private
  Premium
  Public
}

pub fn to_list() -> List(Privacy) {
  [Private, Premium, Public]
}

pub fn from_string(privacy: String) -> Privacy {
  case privacy {
    "Premium" -> Premium
    "Private" -> Private
    "Public" | _ -> Public
  }
}

pub fn to_string(privacy: Privacy) -> String {
  case privacy {
    Public -> "Public"
    Premium -> "Premium"
    Private -> "Private"
  }
}

pub fn privacy_decoder() -> decode.Decoder(Privacy) {
  use variant <- decode.then(decode.string)
  case variant {
    "private" -> decode.success(Private)
    "premium" -> decode.success(Premium)
    "public" -> decode.success(Public)
    _ -> decode.failure(Private, "Privacy")
  }
}

pub fn privacy_to_json(privacy: Privacy) -> json.Json {
  case privacy {
    Private -> json.string("private")
    Premium -> json.string("premium")
    Public -> json.string("public")
  }
}
