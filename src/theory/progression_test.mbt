///|
test "chord progression generation with voice leading" {
  let c_major = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)

  // Progression: I -> vi -> IV -> V
  let prog = generate_progression(c_major, ["I", "vi", "IV", "V"])
  let voicings = prog.unwrap()
  inspect(voicings.length(), content="4")

  // First chord: C Major Triad (C4, E4, G4)
  let v0_strs = voicings[0].map(fn(n) { n.to_string() })
  inspect(format_array(v0_strs), content="[\"C4\", \"E4\", \"G4\"]")

  // Second chord: A Minor Triad (A, C, E) voiced close to v0
  let v1_strs = voicings[1].map(fn(n) { n.to_string() })
  inspect(format_array(v1_strs), content="[\"C4\", \"E4\", \"A4\"]") // C4, E4, A4 minimizes distance from C4, E4, G4

  // Third chord: F Major Triad (F, A, C) voiced close to v1
  let v2_strs = voicings[2].map(fn(n) { n.to_string() })
  inspect(format_array(v2_strs), content="[\"C4\", \"F4\", \"A4\"]")

  // Fourth chord: G Major Triad (G, B, D) voiced close to v2
  let v3_strs = voicings[3].map(fn(n) { n.to_string() })
  inspect(format_array(v3_strs), content="[\"B3\", \"D4\", \"G4\"]")
}
