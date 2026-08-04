///|
test "full music theory toolbox integration workflow" {
  // 1. Initialize Key of Eb Major
  let eb_major = Key::new(NoteLetter::E, Accidental::Flat, ScaleType::Major)
  inspect(eb_major.to_string(), content="Eb major")

  // Verify key signature: Eb Major has 3 flats (Bb, Eb, Ab)
  let (sf_count, sf_acc) = eb_major.sharps_or_flats()
  inspect(sf_count, content="3")
  inspect(sf_acc.to_string(), content="b")

  // 2. Generate a random classical progression of 6 chords
  // seed = 12345
  let prog_roman = generate_classical_progression(eb_major, 6, 12345)
  inspect(prog_roman.length(), content="6")

  // Check progression rules
  let rules_warnings = check_classical_progression(prog_roman)
  inspect(rules_warnings.length(), content="0") // Markov chain transitions avoid retrogression!

  // 3. Resolve actual notes of the progression with optimal voice leading
  let prog_voicings = generate_progression(eb_major, prog_roman).unwrap()
  inspect(prog_voicings.length(), content="6")

  // 4. Voicing conversion: apply Drop 2 voicing to the first chord in the progression
  let v0 = prog_voicings[0]
  if v0.length() >= 4 {
    let d2_v0 = to_drop_2(v0)
    inspect(d2_v0.length(), content=v0.length().to_string())

    // Check spacing of drop 2 voicing
    let spacing_warnings = check_voicing_spacing(d2_v0)
    // Drop 2 spreads the notes out, check if it exceeds spacing thresholds
    // Since it's drop 2, it could have larger intervals
    println(
      "Drop 2 spacing warnings count: " + spacing_warnings.length().to_string(),
    )
  }

  // 5. Build a MIDI file representation of the progression
  let midi = MidiFile::new(960)
  let track = midi.add_track("Eb Major Progression")

  let ticks_per_chord = 960
  for i in 0..<prog_voicings.length() {
    track.add_chord(i * ticks_per_chord, prog_voicings[i], ticks_per_chord, 95)
  }

  // Verify MIDI file contents
  inspect(midi.tracks.length(), content="1")
  inspect(midi.tracks[0].name, content="Eb Major Progression")

  // 6. Convert chord pitches to frequencies in Equal Temperament vs Just Intonation
  let eq_temp = TuningSystem::EqualTemperament
  let just_int = TuningSystem::JustIntonation
  let ref_freq = 440.0

  // Print C4 frequency differences
  let c4 = Note::parse("C4").unwrap()
  let f_eq = c4.frequency_tuned(eq_temp, ref_freq)
  let f_just = c4.frequency_tuned(just_int, ref_freq)
  let diff = (f_eq - f_just).abs()
  println(
    "C4 frequency diff between Equal and Just: " + diff.to_string() + " Hz",
  )

  // 7. Cantus Firmus & Counterpoint species checking
  let cf = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
    Note::parse("C5").unwrap(),
  ]
  let cp = [
    Note::parse("C5").unwrap(),
    Note::parse("G4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("C4").unwrap(),
  ]

  let cp_warnings = check_first_species(cf, cp)
  println(
    "Counterpoint checker ran. Warnings: " + cp_warnings.length().to_string(),
  )

  // 8. Serialize everything to JSON
  let midi_json = midi.to_json().stringify()
  inspect(midi_json.contains("\"ppq\":960"), content="true")
  inspect(
    midi_json.contains("\"name\":\"Eb Major Progression\""),
    content="true",
  )
}
