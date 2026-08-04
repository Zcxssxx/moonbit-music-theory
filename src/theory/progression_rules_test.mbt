///|
test "classical progression checker and generator" {
  // Correct progression: I -> ii -> V -> I
  let p1 = ["I", "ii", "V", "I"]
  let warnings1 = check_classical_progression(p1)
  inspect(warnings1.length(), content="0")

  // Retrogression progression: I -> V -> IV -> I (V -> IV is retrogression)
  let p2 = ["I", "V", "IV", "I"]
  let warnings2 = check_classical_progression(p2)
  inspect(warnings2.length(), content="1")
  inspect(
    warnings2[0],
    content="Functional harmony retrogression at index 1: Dominant chord 'V' followed by Subdominant 'IV'.",
  )

  // Generate a random classical progression
  let c_major = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let generated = generate_classical_progression(c_major, 6, 42)
  inspect(generated.length(), content="6")

  // Verify that the generated progression has no retrogressions
  let warnings_gen = check_classical_progression(generated)
  inspect(warnings_gen.length(), content="0")
}

///|
test "progression cadence detection" {
  // PAC: V -> I
  inspect(detect_cadence("V7", "I"), content="Authentic Cadence (AC)")

  // Plagal: IV -> I
  inspect(detect_cadence("IV", "I"), content="Plagal Cadence (PC)")

  // Deceptive: V -> vi
  inspect(detect_cadence("V", "vi"), content="Deceptive Cadence (DC)")

  // Half: I -> V
  inspect(detect_cadence("I", "V"), content="Half Cadence (HC)")

  // Test progression cadences: I -> IV -> V7 -> I -> vi
  let cads = analyze_progression_cadences(["I", "IV", "V7", "I", "vi"])
  inspect(cads.length(), content="2")

  // IV -> V7 at index 1 is Half Cadence (HC)
  let (idx1, type1) = cads[0]
  inspect(idx1, content="1")
  inspect(type1, content="Half Cadence (HC)")

  // V7 -> I at index 2 is Authentic Cadence (AC)
  let (idx2, type2) = cads[1]
  inspect(idx2, content="2")
  inspect(type2, content="Authentic Cadence (AC)")

  // I -> vi is not a standard cadence in this matcher, but wait:
  // clean1 = "I", clean2 = "vi" -> "None"
}
