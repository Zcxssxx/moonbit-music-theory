///|
test "json serialization and deserialization" {
  let note = Note::parse("C#4").unwrap()
  let note_json = note.to_json()
  inspect(note_json.stringify(), content="\"C#4\"")

  let note_decoded : Result[Note, String] = Ok(@json.from_json(note_json)) catch {
    e => Err(e.to_string())
  }
  let note_decoded_str = match note_decoded {
    Ok(n) => "Ok(" + n.to_string() + ")"
    Err(err) => "Err(" + err + ")"
  }
  inspect(note_decoded_str, content="Ok(C#4)")

  let interval = Interval::parse("M3").unwrap()
  let interval_json = interval.to_json()
  inspect(interval_json.stringify(), content="\"M3\"")

  let interval_decoded : Result[Interval, String] = Ok(
    @json.from_json(interval_json),
  ) catch {
    e => Err(e.to_string())
  }
  let interval_decoded_str = match interval_decoded {
    Ok(inv) => "Ok(" + inv.to_string() + ")"
    Err(err) => "Err(" + err + ")"
  }
  inspect(interval_decoded_str, content="Ok(M3)")

  let key = Key::new(NoteLetter::F, Accidental::Sharp, ScaleType::Minor)
  let key_json = key.to_json()
  inspect(key_json.stringify(), content="\"F# minor\"")

  let key_decoded : Result[Key, String] = Ok(@json.from_json(key_json)) catch {
    e => Err(e.to_string())
  }
  let key_decoded_str = match key_decoded {
    Ok(k) => "Ok(" + k.to_string() + ")"
    Err(err) => "Err(" + err + ")"
  }
  inspect(key_decoded_str, content="Ok(F# minor)")
}
