///|
test "acceptance integration preserves score report and SMF semantics" {
  let score = Score::new(480)
  let track = score.add_track("integration")
  let c4 = Note::parse("C4").unwrap()
  let e4 = Note::parse("E4").unwrap()
  track.add_note(NoteEvent::new(c4, 0, 480, 100, 0))
  track.add_note(NoteEvent::new(e4, 480, 480, 100, 0))
  track.add_chord(ChordEvent::new(c4, ChordType::MajorTriad, 0, 960, 90, 0))

  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(score, key)
  inspect(report.duration_ticks, content="960")
  inspect(report.note_event_count, content="2")
  inspect(report.chord_event_count, content="1")
  assert_true(report.to_text().contains("pitch-class histogram"))
  assert_true(report.to_json().stringify().contains("harmony_summary"))

  let midi = MidiFile::new(480)
  let midi_track = midi.add_track("integration-midi")
  midi_track.add_chord(0, [c4, e4], 480, 90)
  let decoded = MidiFile::from_smf(midi.to_smf())
  inspect(decoded.tracks.length(), content="1")
  inspect(decoded.tracks[0].events.length(), content="4")
}

///|
test "acceptance integration keeps repeated report calls deterministic" {
  let score = Score::new(480)
  let track = score.add_track("determinism")
  track.add_note(NoteEvent::new(Note::parse("G4").unwrap(), 0, 240, 90, 0))
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let first = analyze_score(score, key)
  let second = analyze_score(score, key)
  inspect(first.to_text() == second.to_text(), content="true")
  inspect(first.to_json() == second.to_json(), content="true")
}
