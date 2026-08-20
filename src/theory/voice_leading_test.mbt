///|
fn format_notes(notes : Array[Note]) -> String {
  let strs = notes.map(fn(note) { note.to_string() })
  let mut res = "["
  for i in 0..<strs.length() {
    if i > 0 {
      res = res + ", "
    }
    res = res + "\"" + strs[i] + "\""
  }
  res = res + "]"
  res
}

///|
fn failure_detail(message : String) -> String {
  let marker = " FAILED: "
  let pieces = message.split(marker).collect()
  let detail = if pieces.length() > 1 {
    pieces[pieces.length() - 1].to_owned()
  } else {
    message
  }
  if detail.has_suffix(")") {
    detail[:detail.length() - 1].to_owned()
  } else {
    detail
  }
}

///|
test "voice leading keeps common tones when costs tie" {
  let start = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
  ]
  let result = solve_voice_leading(
    start,
    Note::parse("F4").unwrap(),
    ChordType::MajorTriad,
    VoiceLeadingOptions::default(),
  )

  inspect(result.total_semitone_motion, content="2")
  assert_true(result.common_tones >= 1)
  inspect(
    format_notes(result.target_voicing),
    content="[\"C4\", \"F4\", \"A4\"]",
  )
}

///|
test "voice leading reports an impossible register" {
  let options = VoiceLeadingOptions::new(
    lowest_midi=80,
    highest_midi=60,
    max_spacing=12,
  )

  try
    solve_voice_leading(
      [],
      Note::parse("C4").unwrap(),
      ChordType::MajorTriad,
      options,
    )
  catch {
    err =>
      inspect(
        failure_detail(err.to_string()),
        content="lowest MIDI must not exceed highest MIDI",
      )
  } noraise {
    _ => fail("expected invalid register error")
  }
}

///|
test "voice leading rejects candidates that violate spacing or range constraints" {
  let start = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
  ]
  let options = VoiceLeadingOptions::new(
    lowest_midi=60,
    highest_midi=72,
    max_spacing=3,
  )

  try
    solve_voice_leading(
      start,
      Note::parse("F4").unwrap(),
      ChordType::MajorTriad,
      options,
    )
  catch {
    err =>
      inspect(
        err
        .to_string()
        .contains(
          "no valid voice-leading candidate satisfied the range and spacing constraints",
        ),
        content="true",
      )
  } noraise {
    _ => fail("expected impossible constrained voicing")
  }
}

///|
test "voice leading handles an empty start voicing deterministically" {
  let options = VoiceLeadingOptions::new(
    lowest_midi=60,
    highest_midi=67,
    max_spacing=12,
  )
  let result = solve_voice_leading(
    [],
    Note::parse("C4").unwrap(),
    ChordType::MajorTriad,
    options,
  )

  inspect(
    format_notes(result.target_voicing),
    content="[\"C4\", \"E4\", \"G4\"]",
  )
  inspect(result.total_semitone_motion, content="0")
  inspect(result.common_tones, content="0")
}

///|
test "voice leading retains all common tones for identical target harmony" {
  let start = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
  ]
  let result = solve_voice_leading(
    start,
    Note::parse("C4").unwrap(),
    ChordType::MajorTriad,
    VoiceLeadingOptions::default(),
  )

  inspect(
    format_notes(result.target_voicing),
    content="[\"C4\", \"E4\", \"G4\"]",
  )
  inspect(result.total_semitone_motion, content="0")
  inspect(result.common_tones, content="3")
}

///|
test "voice leading preserves four voices when targeting a triad" {
  let start = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
    Note::parse("C5").unwrap(),
  ]
  let result = solve_voice_leading(
    start,
    Note::parse("F4").unwrap(),
    ChordType::MajorTriad,
    VoiceLeadingOptions::default(),
  )

  inspect(result.target_voicing.length(), content="4")
  inspect(result.voice_movements.length(), content="4")
  inspect(result.cost.lexicographic_midi.length(), content="4")
  inspect(
    format_notes(result.target_voicing),
    content="[\"C4\", \"F4\", \"A4\", \"C5\"]",
  )
}

///|
test "voice leading common tones match exact MIDI occurrences as a multiset" {
  let start = [
    Note::parse("C4").unwrap(),
    Note::parse("C4").unwrap(),
    Note::parse("G4").unwrap(),
  ]
  let result = solve_voice_leading(
    start,
    Note::parse("C4").unwrap(),
    ChordType::MajorTriad,
    VoiceLeadingOptions::default(),
  )

  inspect(
    format_notes(result.target_voicing),
    content="[\"C4\", \"E4\", \"G4\"]",
  )
  inspect(result.common_tones, content="2")
}
