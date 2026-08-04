///|
test "pitch parsing and midi conversion" {
  let note1 = Note::parse("C4")
  let note1_str = match note1 {
    Ok(n) => "Ok(" + n.to_string() + ")"
    Err(e) => "Err(" + e + ")"
  }
  inspect(note1_str, content="Ok(C4)")
  inspect(note1.unwrap().to_midi(), content="60")

  let note2 = Note::parse("F#3")
  let note2_str = match note2 {
    Ok(n) => "Ok(" + n.to_string() + ")"
    Err(e) => "Err(" + e + ")"
  }
  inspect(note2_str, content="Ok(F#3)")
  inspect(note2.unwrap().to_midi(), content="54")

  let note3 = Note::parse("Bb-1")
  let note3_str = match note3 {
    Ok(n) => "Ok(" + n.to_string() + ")"
    Err(e) => "Err(" + e + ")"
  }
  inspect(note3_str, content="Ok(Bb-1)")
  inspect(note3.unwrap().to_midi(), content="10")

  let note4 = Note::from_midi(60)
  inspect(note4.to_string(), content="C4")
}
