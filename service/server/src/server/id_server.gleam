import gleam/bit_array
import gleam/erlang/process.{type Name, type Subject}
import gleam/io
import gleam/string

pub type IdServerMessage {
  GenerateId(reply: Subject(String))
}

@external(erlang, "id_server_ffi", "init")
fn init_rand() -> Nil

@external(erlang, "id_server_ffi", "generate")
fn generate_bytes() -> BitArray

pub fn start() -> Name(IdServerMessage) {
  let name = process.new_name("id_server")

  let pid = process.spawn(fn() {
    init_rand()
    io.println("id_server: init_rand done")
    loop(name, True)
  })

  let assert Ok(_) = process.register(pid, name)
  name
}

fn loop(name: Name(IdServerMessage), first: Bool) -> Nil {
  let subject = process.named_subject(name)

  case process.receive(subject, within: 60_000) {
    Ok(GenerateId(reply: reply_subject)) -> {
      let id =
        generate_bytes()
        |> bit_array.base64_url_encode(False)
        |> string.slice(at_index: 1, length: 11)
      case first {
        True -> io.println("id_server: first request generated = " <> id)
        False -> Nil
      }
      process.send(reply_subject, id)
      loop(name, False)
    }
    Error(Nil) -> loop(name, first)
  }
}
