///|
test "chord parsing and generation" {
  // Cmaj7
  let parsed1 = parse_chord_symbol("Cmaj7")
  let (root1, type1) = parsed1.unwrap()
  inspect(root1.to_string(), content="C4")
  inspect(type1.to_string(), content="major_seventh")
  let notes1 = generate_chord(root1, type1)
  let strs1 = notes1.map(fn(n) { n.to_string() })
  inspect(format_array(strs1), content="[\"C4\", \"E4\", \"G4\", \"B4\"]")

  // Cm7 with custom octave
  let parsed2 = parse_chord_symbol("Ab5m7")
  let (root2, type2) = parsed2.unwrap()
  inspect(root2.to_string(), content="Ab5")
  inspect(type2.to_string(), content="minor_seventh")
  let notes2 = generate_chord(root2, type2)
  let strs2 = notes2.map(fn(n) { n.to_string() })
  inspect(format_array(strs2), content="[\"Ab5\", \"Cb6\", \"Eb6\", \"Gb6\"]")
}

///|
test "extended and suspended chords" {
  let (root, ty) = parse_chord_symbol("Cmaj9").unwrap()
  let notes = generate_chord(root, ty)
  let strs = notes.map(fn(n) { n.to_string() })
  inspect(
    format_array(strs),
    content="[\"C4\", \"E4\", \"G4\", \"B4\", \"D5\"]",
  )

  let (root_sus, ty_sus) = parse_chord_symbol("Csus4").unwrap()
  let notes_sus = generate_chord(root_sus, ty_sus)
  let strs_sus = notes_sus.map(fn(n) { n.to_string() })
  inspect(format_array(strs_sus), content="[\"C4\", \"F4\", \"G4\"]")
}

///|
test "slash chords and inversions" {
  let notes_inv1 = generate_chord_inversion(
    Note::parse("C4").unwrap(),
    ChordType::MajorTriad,
    1,
  )
  let strs_inv1 = notes_inv1.map(fn(n) { n.to_string() })
  inspect(format_array(strs_inv1), content="[\"E4\", \"G4\", \"C5\"]") // First inversion of C Major: E4, G4, C5

  let (root, ty, inv) = parse_slash_chord("C/G").unwrap()
  inspect(root.to_string(), content="C4")
  inspect(ty.to_string(), content="major")
  inspect(inv, content="2") // G is index 2 (5th of C major)
}

///|
test "optimal voice leading" {
  // transition C4 Major Triad (C4, E4, G4) to G Major Triad (G, B, D)
  let c_maj = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
  ]
  let target_root = Note::parse("G4").unwrap()

  let optimal = find_optimal_voicing(c_maj, target_root, ChordType::MajorTriad)
  let optimal_strs = optimal.map(fn(n) { n.to_string() })
  // G major in a close voicing to [C4, E4, G4] is [B3, D4, G4] or similar
  inspect(format_array(optimal_strs), content="[\"B3\", \"D4\", \"G4\"]")
}
