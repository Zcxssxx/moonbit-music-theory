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

///|
test "key signature sharps or flats" {
  let c_maj = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let (count_c, acc_c) = c_maj.sharps_or_flats()
  inspect(count_c, content="0")
  inspect(acc_c.to_string(), content="")

  let d_maj = Key::new(NoteLetter::D, Accidental::Natural, ScaleType::Major)
  let (count_d, acc_d) = d_maj.sharps_or_flats()
  inspect(count_d, content="2")
  inspect(acc_d.to_string(), content="#")

  let f_maj = Key::new(NoteLetter::F, Accidental::Natural, ScaleType::Major)
  let (count_f, acc_f) = f_maj.sharps_or_flats()
  inspect(count_f, content="1")
  inspect(acc_f.to_string(), content="b")

  let g_min = Key::new(NoteLetter::G, Accidental::Natural, ScaleType::Minor)
  // relative major is Bb major (2 flats)
  let (count_g, acc_g) = g_min.sharps_or_flats()
  inspect(count_g, content="2")
  inspect(acc_g.to_string(), content="b")
}

///|
test "chord from roman translation" {
  let c_major = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)

  inspect(c_major.chord_from_roman("I").unwrap(), content="C")
  inspect(c_major.chord_from_roman("ii").unwrap(), content="Dm")
  inspect(c_major.chord_from_roman("V7").unwrap(), content="G7")
  inspect(c_major.chord_from_roman("bIII").unwrap(), content="Eb")
  inspect(c_major.chord_from_roman("vii°").unwrap(), content="Bdim")
}

///|
test "relative and parallel key relations" {
  let c_major = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let a_minor = Key::new(NoteLetter::A, Accidental::Natural, ScaleType::Minor)

  // relative minor of C major is A minor
  let rel_min = c_major.relative_minor().unwrap()
  inspect(rel_min.root.to_string(), content="A")
  inspect(rel_min.scale_type.to_string(), content="minor")

  // relative major of A minor is C major
  let rel_maj = a_minor.relative_major().unwrap()
  inspect(rel_maj.root.to_string(), content="C")
  inspect(rel_maj.scale_type.to_string(), content="major")

  // parallel key of C major is C minor
  let c_minor = c_major.parallel_key()
  inspect(c_minor.root.to_string(), content="C")
  inspect(c_minor.scale_type.to_string(), content="minor")
}
