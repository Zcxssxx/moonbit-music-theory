///|
test "roman numeral analysis" {
  let c_major = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)

  let test_cases = [
    ("C", "Ok(I)"),
    ("Dm", "Ok(ii)"),
    ("G7", "Ok(V7)"),
    ("Bdim", "Ok(vii°)"),
    ("Eb", "Ok(bIII)"),
    ("F#m", "Ok(#iv)"),
  ]

  for tc in test_cases {
    let chord = tc.0
    let expected = tc.1
    let actual = match c_major.analyze_chord(chord) {
      Ok(r) => "Ok(" + r + ")"
      Err(e) => "Err(" + e + ")"
    }
    inspect(actual, content=expected)
  }

  let a_minor = Key::new(NoteLetter::A, Accidental::Natural, ScaleType::Minor)
  let a_minor_cases = [("Am", "Ok(i)"), ("Dm", "Ok(iv)"), ("E7", "Ok(V7)")]

  for tc in a_minor_cases {
    let chord = tc.0
    let expected = tc.1
    let actual = match a_minor.analyze_chord(chord) {
      Ok(r) => "Ok(" + r + ")"
      Err(e) => "Err(" + e + ")"
    }
    inspect(actual, content=expected)
  }
}
