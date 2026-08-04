///|
test "species counterpoint rule checker" {
  // Correct first species counterpoint example
  let cf = [
    Note::parse("C4").unwrap(),
    Note::parse("D4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("D4").unwrap(),
    Note::parse("C4").unwrap(),
  ]

  let cp_correct = [
    Note::parse("C5").unwrap(),
    Note::parse("B4").unwrap(),
    Note::parse("G4").unwrap(),
    Note::parse("B4").unwrap(),
    Note::parse("C5").unwrap(),
  ]

  let warnings1 = check_first_species(cf, cp_correct)
  // All consonant thirds, no voice crossing, perfect start/end.
  inspect(warnings1.length(), content="0")

  // Incorrect: voice crossing
  let cp_crossing = [
    Note::parse("C5").unwrap(),
    Note::parse("C4").unwrap(), // CP goes below CF (which is D4) -> voice crossing!
    Note::parse("G4").unwrap(),
    Note::parse("B4").unwrap(),
    Note::parse("C5").unwrap(),
  ]
  let warnings2 = check_first_species(cf, cp_crossing)
  inspect(warnings2.length(), content="2")
  inspect(warnings2[1].rule_name, content="VoiceCrossing")

  // Incorrect: parallel fifths
  let cf_parallel = [
    Note::parse("C4").unwrap(),
    Note::parse("D4").unwrap(),
    Note::parse("E4").unwrap(),
  ]
  let cp_parallel = [
    Note::parse("G4").unwrap(),
    Note::parse("A4").unwrap(),
    Note::parse("B4").unwrap(),
  ]
  let warnings3 = check_first_species(cf_parallel, cp_parallel)
  // G4/C4 = 5th, A4/D4 = 5th, B4/E4 = 5th.
  // This causes parallel fifths at index 1 and 2, plus invalid end interval!
  inspect(warnings3.length(), content="3")
  inspect(warnings3[1].rule_name, content="ParallelFifths")
  inspect(warnings3[2].rule_name, content="ParallelFifths")
}
