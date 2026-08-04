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
