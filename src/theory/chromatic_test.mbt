///|
test "chromatic augmented sixth and neapolitan chords" {
  let c_major = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)

  // Italian 6th in C: Ab4, C5, F#5
  let it6 = generate_augmented_sixth(c_major, AugmentedSixthType::Italian)
  let it6_strs = it6.map(fn(n) { n.to_string() })
  inspect(format_array(it6_strs), content="[\"Ab4\", \"C5\", \"F#5\"]")

  // French 6th in C: Ab4, C5, D5, F#5
  let fr6 = generate_augmented_sixth(c_major, AugmentedSixthType::French)
  let fr6_strs = fr6.map(fn(n) { n.to_string() })
  inspect(format_array(fr6_strs), content="[\"Ab4\", \"C5\", \"D5\", \"F#5\"]")

  // German 6th in C: Ab4, C5, Eb5, F#5
  let ger6 = generate_augmented_sixth(c_major, AugmentedSixthType::German)
  let ger6_strs = ger6.map(fn(n) { n.to_string() })
  inspect(
    format_array(ger6_strs),
    content="[\"Ab4\", \"C5\", \"Eb5\", \"F#5\"]",
  )

  // Neapolitan 6th in C: F4, Ab4, Db5 (Db major triad in 1st inversion)
  let n6 = generate_neapolitan_sixth(c_major)
  let n6_strs = n6.map(fn(n) { n.to_string() })
  inspect(format_array(n6_strs), content="[\"F4\", \"Ab4\", \"Db5\"]")
}
