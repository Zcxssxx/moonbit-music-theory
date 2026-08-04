///|
test "chord voicing drop 2, drop 3 and spacing checks" {
  // C major seventh close voicing: C4, E4, G4, B4 (60, 64, 67, 71)
  let c_maj7 = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
    Note::parse("B4").unwrap(),
  ]

  // Drop 2: drops the second highest (G4 = 67) down an octave to G3 (55)
  // Voicing becomes: G3, C4, E4, B4
  let drop2 = to_drop_2(c_maj7)
  let d2_strs = drop2.map(fn(n) { n.to_string() })
  inspect(format_array(d2_strs), content="[\"G3\", \"C4\", \"E4\", \"B4\"]")

  // Drop 3: drops the third highest (E4 = 64) down an octave to E3 (52)
  // Voicing becomes: E3, C4, G4, B4
  let drop3 = to_drop_3(c_maj7)
  let d3_strs = drop3.map(fn(n) { n.to_string() })
  inspect(format_array(d3_strs), content="[\"E3\", \"C4\", \"G4\", \"B4\"]")

  // Spacing checker: C4, E4, G5 (diff between E4 and G5 is 15 semitones -> warning!)
  let wide = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G5").unwrap(),
  ]
  let warnings = check_voicing_spacing(wide)
  inspect(warnings.length(), content="1")
  inspect(
    warnings[0],
    content="Spacing warning: Interval between upper voices E4 and G5 is 15 semitones, exceeding one octave.",
  )
}
