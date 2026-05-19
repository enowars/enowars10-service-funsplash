pub type Config {
  Config(secret: String)
}

pub fn config() {
  Config("secret")
}
