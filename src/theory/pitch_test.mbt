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

///|
test "double accidentals parsing and midi" {
  let note_dsharp = Note::parse("C##4").unwrap()
  inspect(note_dsharp.to_string(), content="C##4")
  inspect(note_dsharp.to_midi(), content="62")

  let note_dflat = Note::parse("Dbb4").unwrap()
  inspect(note_dflat.to_string(), content="Dbb4")
  inspect(note_dflat.to_midi(), content="60") // D4=62. DoubleFlat = -2. 62 - 2 = 60.
  inspect(note_dflat.to_midi(), content="60")

  let note_x = Note::parse("Cx4").unwrap()
  inspect(note_x.to_string(), content="C##4")
  inspect(note_x.to_midi(), content="62")
}

///|
test "pitch frequency conversion" {
  let a4 = Note::parse("A4").unwrap()
  let freq = a4.to_frequency(440.0)
  inspect(freq, content="440")

  let c4 = Note::parse("C4").unwrap()
  let c4_freq = c4.to_frequency(440.0)
  // 440.0 * 2^(-9/12) = 261.6255653005986
  inspect(c4_freq, content="261.6255653005986")

  let parsed_c4 = Note::from_frequency(261.63, 440.0)
  inspect(parsed_c4.to_string(), content="C4")
}
