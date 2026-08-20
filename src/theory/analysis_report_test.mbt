///|
fn demo_score() -> Score raise Failure {
  let score = Score::new(480)
  let melody = score.add_track("melody")
  melody.add_note(NoteEvent::new(Note::parse("C4").unwrap(), 0, 480, 100, 0))
  melody.add_note(NoteEvent::new(Note::parse("E4").unwrap(), 480, 480, 96, 0))
  melody.add_note(NoteEvent::new(Note::parse("G4").unwrap(), 960, 480, 92, 0))
  melody.add_note(NoteEvent::new(Note::parse("C5").unwrap(), 1440, 480, 88, 0))

  let harmony = score.add_track("harmony")
  harmony.add_chord(
    ChordEvent::new(
      Note::parse("C4").unwrap(),
      ChordType::MajorTriad,
      0,
      480,
      80,
      1,
    ),
  )
  harmony.add_chord(
    ChordEvent::new(
      Note::parse("F4").unwrap(),
      ChordType::MajorTriad,
      480,
      480,
      80,
      1,
    ),
  )
  harmony.add_chord(
    ChordEvent::new(
      Note::parse("G4").unwrap(),
      ChordType::DominantSeventh,
      960,
      480,
      80,
      1,
    ),
  )
  harmony.add_chord(
    ChordEvent::new(
      Note::parse("C4").unwrap(),
      ChordType::MajorTriad,
      1440,
      480,
      80,
      1,
    ),
  )
  score
}

///|
fn sparse_score() -> Score raise Failure {
  let score = Score::new(480)
  let empty = score.add_track("empty")
  let _ = empty
  let melody = score.add_track("rests")
  melody.add_note(NoteEvent::new(Note::parse("C4").unwrap(), 480, 240, 90, 0))
  melody.add_note(NoteEvent::new(Note::parse("G4").unwrap(), 1440, 240, 90, 0))
  score
}

///|
fn misaligned_counterpoint_score() -> Score raise Failure {
  let score = Score::new(480)
  let cf = score.add_track("cf")
  cf.add_note(NoteEvent::new(Note::parse("C4").unwrap(), 0, 480, 90, 0))
  cf.add_note(NoteEvent::new(Note::parse("D4").unwrap(), 480, 480, 90, 0))
  cf.add_note(NoteEvent::new(Note::parse("E4").unwrap(), 960, 480, 90, 0))

  let cp = score.add_track("cp")
  cp.add_note(NoteEvent::new(Note::parse("G4").unwrap(), 240, 480, 90, 1))
  cp.add_note(NoteEvent::new(Note::parse("A4").unwrap(), 720, 480, 90, 1))
  cp.add_note(NoteEvent::new(Note::parse("B4").unwrap(), 1200, 480, 90, 1))
  score
}

///|
fn unsupported_meter_score() -> Score raise Failure {
  let score = Score::new(480, time_signature=TimeSignature::new(5, 4))
  let melody = score.add_track("five")
  melody.add_note(NoteEvent::new(Note::parse("C4").unwrap(), 0, 480, 90, 0))
  melody.add_note(NoteEvent::new(Note::parse("E4").unwrap(), 480, 480, 90, 0))
  score
}

///|
fn split_track_harmony_score() -> Score raise Failure {
  let score = Score::new(480)
  let late_track = score.add_track("late_track")
  late_track.add_chord(
    ChordEvent::new(
      Note::parse("F4").unwrap(),
      ChordType::MajorTriad,
      480,
      480,
      80,
      1,
    ),
  )
  late_track.add_chord(
    ChordEvent::new(
      Note::parse("G4").unwrap(),
      ChordType::MajorTriad,
      960,
      480,
      80,
      1,
    ),
  )

  let early_track = score.add_track("early_track")
  early_track.add_chord(
    ChordEvent::new(
      Note::parse("C4").unwrap(),
      ChordType::MajorTriad,
      0,
      480,
      80,
      1,
    ),
  )
  score
}

///|
test "score report is deterministic and includes musical dimensions" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(demo_score(), key)

  inspect(
    report.pitch_histogram,
    content="[2, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]",
  )
  inspect(report.duration_ticks, content="1920")
  inspect(report.note_event_count, content="4")
  inspect(report.chord_event_count, content="4")
  debug_inspect(report.melodic_intervals, content="[4, 3, 5]")
  inspect(report.register_min.unwrap().to_string(), content="C4")
  inspect(report.register_max.unwrap().to_string(), content="C5")
  assert_true(report.text().contains("pitch-class histogram"))
}

///|
test "score report text snapshot stays stable" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(demo_score(), key)

  inspect(
    report.to_text(),
    content=(
      #|Score report
      #|duration_ticks: 1920
      #|tracks: 2
      #|note_events: 4
      #|chord_events: 4
      #|pitch-class histogram: [2, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]
      #|register: C4..C5
      #|melodic_intervals: [4, 3, 5]
      #|rhythm: meter_supported=true beat_ticks=480 beats=4 average_duration_ticks=480 density_per_beat_milli=1000 syncopation=0 on_beat=4 off_beat=0
      #|harmony: symbols=4 cadence=Authentic tonic=2 predominant=1 dominant=1 ambiguous=0 findings=0
      #|voice_leading_warnings: 0
      #|
    ),
  )
}

///|
test "score report summarizes rhythm and harmony deterministically" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(demo_score(), key)

  inspect(report.rhythm_summary.meter_supported, content="true")
  inspect(report.rhythm_summary.beat_ticks, content="480")
  inspect(report.rhythm_summary.beat_count, content="4")
  inspect(report.rhythm_summary.average_duration_ticks, content="480")
  inspect(report.rhythm_summary.density_per_beat_milli, content="1000")
  inspect(report.rhythm_summary.syncopation, content="0")
  inspect(report.rhythm_summary.on_beat_attacks, content="4")
  inspect(report.rhythm_summary.off_beat_attacks, content="0")

  inspect(report.harmony_summary.symbol_count, content="4")
  inspect(report.harmony_summary.cadence.to_string(), content="Authentic")
  inspect(report.harmony_summary.tonic_count, content="2")
  inspect(report.harmony_summary.predominant_count, content="1")
  inspect(report.harmony_summary.dominant_count, content="1")
  inspect(report.harmony_summary.ambiguous_count, content="0")
  inspect(report.harmony_summary.finding_count, content="0")
}

///|
test "score report handles empty scores tracks and rests deterministically" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let empty = analyze_score(Score::new(480), key)
  let sparse = analyze_score(sparse_score(), key)

  inspect(empty.pitch_histogram, content="[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]")
  inspect(empty.duration_ticks, content="0")
  debug_inspect(empty.register_min, content="None")
  debug_inspect(empty.register_max, content="None")
  inspect(empty.rhythm_summary.average_duration_ticks, content="0")
  inspect(empty.harmony_summary.cadence.to_string(), content="Undetermined")
  inspect(empty.to_text().contains("register: none"), content="true")

  inspect(sparse.note_event_count, content="2")
  inspect(sparse.duration_ticks, content="1680")
  debug_inspect(sparse.melodic_intervals, content="[7]")
}

///|
test "score report ignores misaligned equal-length tracks for voice-leading warnings" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(misaligned_counterpoint_score(), key)

  inspect(report.voice_leading_warning_count, content="0")
}

///|
test "score report zeros rhythm metrics for unsupported meters" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(unsupported_meter_score(), key)

  inspect(report.rhythm_summary.meter_supported, content="false")
  inspect(report.rhythm_summary.beat_ticks, content="0")
  inspect(report.rhythm_summary.beat_count, content="0")
  inspect(report.rhythm_summary.density_per_beat_milli, content="0")
  inspect(report.rhythm_summary.syncopation, content="0")
  inspect(report.rhythm_summary.on_beat_attacks, content="0")
  inspect(report.rhythm_summary.off_beat_attacks, content="0")
  inspect(report.to_text().contains("meter_supported=false"), content="true")
}

///|
test "score report orders chord events globally by tick before harmony summary" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(split_track_harmony_score(), key)

  inspect(report.chord_event_count, content="3")
  inspect(report.harmony_summary.symbol_count, content="3")
  inspect(report.harmony_summary.tonic_count, content="1")
  inspect(report.harmony_summary.predominant_count, content="1")
  inspect(report.harmony_summary.dominant_count, content="1")
  inspect(report.harmony_summary.cadence.to_string(), content="Half")
}

///|
test "score report stays stable across repeated calls" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let score = demo_score()
  let report1 = analyze_score(score, key)
  let report2 = analyze_score(score, key)

  inspect(report1.to_text() == report2.to_text(), content="true")
  inspect(report1.to_json() == report2.to_json(), content="true")
}
