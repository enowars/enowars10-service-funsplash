import gleam/bit_array
import gleam/erlang/process.{type Name, type Subject}
import gleam/string

pub type IdServerMessage {
  GenerateId(reply: Subject(String))
}

pub fn start() -> Name(IdServerMessage) {
  let name = process.new_name("id_server")

  let pid = process.spawn(fn() { loop(name, 0) })

  let assert Ok(_) = process.register(pid, name)
  name
}

fn loop(name: Name(IdServerMessage), counter: Int) -> Nil {
  let subject = process.named_subject(name)

  case process.receive(subject, within: 60_000) {
    Ok(GenerateId(reply: reply_subject)) -> {
      let id =
        <<counter:72>>
        |> bit_array.base64_url_encode(False)
        |> string.slice(at_index: 1, length: 11)
      process.send(reply_subject, id)
      loop(name, counter + 1)
    }
    Error(Nil) -> loop(name, counter)
  }
}
