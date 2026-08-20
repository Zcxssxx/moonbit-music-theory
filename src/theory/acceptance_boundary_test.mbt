///|
test "acceptance boundaries cover empty score and unsupported meter" {
  let empty = analyze_score(
    Score::new(480),
    Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major),
  )
  inspect(empty.duration_ticks, content="0")
  inspect(empty.note_event_count, content="0")
  inspect(empty.rhythm_summary.meter_supported, content="true")
  assert_true(empty.register_min is None)

  let odd_meter = Score::new(480, time_signature=TimeSignature::new(5, 4))
  let report = analyze_score(
    odd_meter,
    Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major),
  )
  inspect(report.rhythm_summary.meter_supported, content="false")
  inspect(report.rhythm_summary.beat_ticks, content="0")
  inspect(report.rhythm_summary.beat_count, content="0")
}

///|
test "acceptance boundaries reject invalid voice range and malformed MIDI" {
  try
    solve_voice_leading(
      [],
      Note::parse("C4").unwrap(),
      ChordType::MajorTriad,
      VoiceLeadingOptions::new(lowest_midi=80, highest_midi=60, max_spacing=12),
    )
  catch {
    err =>
      assert_true(
        err.to_string().contains("lowest MIDI must not exceed highest MIDI"),
      )
  } noraise {
    _ => fail("expected invalid voice range")
  }

  try MidiFile::from_smf([b'M', b'T', b'h', b'd', 0, 0, 0, 6]) catch {
    err =>
      inspect(err.to_string(), content="unexpected end of MIDI data at header")
  } noraise {
    _ => fail("expected malformed MIDI error")
  }
}

///|
test "acceptance boundaries keep extreme supported MIDI notes stable" {
  let low = Note::from_midi(0)
  let high = Note::from_midi(127)
  inspect(low.to_midi(), content="0")
  inspect(high.to_midi(), content="127")
  inspect(low.transpose(Interval::parse("P8").unwrap()).to_midi(), content="12")
}
