///|
fn parse_iterations(args : Array[String]) -> Int {
  if args.length() < 2 {
    return 1
  }
  let mut value = 0
  for ch in args[1] {
    let digit = ch.to_int() - '0'.to_int()
    if digit < 0 || digit > 9 {
      return 1
    }
    value = value * 10 + digit
  }
  if value > 0 {
    value
  } else {
    1
  }
}

///|
fn fixture_score() -> @theory.Score raise Failure {
  let score = @theory.Score::new(480)
  let track = score.add_track("benchmark")
  let roots = ["C4", "F4", "G4", "C4"]
  let types = [
    @theory.ChordType::MajorTriad,
    @theory.ChordType::MajorTriad,
    @theory.ChordType::DominantSeventh,
    @theory.ChordType::MajorTriad,
  ]
  for i in 0..<roots.length() {
    let root = @theory.Note::parse(roots[i]).unwrap()
    track.add_chord(
      @theory.ChordEvent::new(root, types[i], i * 480, 480, 90, 0),
    )
    track.add_note(@theory.NoteEvent::new(root, i * 480, 480, 90, 0))
  }
  score
}

///|
fn main raise Failure {
  let iterations = parse_iterations(@env.args())
  let score = fixture_score()
  let key = @theory.Key::new(
    @theory.NoteLetter::C,
    @theory.Accidental::Natural,
    @theory.ScaleType::Major,
  )
  let start = [
    @theory.Note::parse("C4").unwrap(),
    @theory.Note::parse("E4").unwrap(),
    @theory.Note::parse("G4").unwrap(),
  ]
  let target = @theory.Note::parse("F4").unwrap()
  let midi = @theory.MidiFile::new(480)
  let midi_track = midi.add_track("benchmark-midi")
  midi_track.add_chord(0, start, 480, 90)
  let mut checksum = 0
  for _ in 0..<iterations {
    let report = @theory.analyze_score(score, key)
    let leading = @theory.solve_voice_leading(
      start,
      target,
      @theory.ChordType::MajorTriad,
      @theory.VoiceLeadingOptions::default(),
    )
    let decoded = @theory.MidiFile::from_smf(midi.to_smf()) catch {
      err => abort(err.to_string())
    }
    checksum += report.duration_ticks +
      report.note_event_count +
      report.chord_event_count +
      leading.total_semitone_motion +
      decoded.tracks.length() +
      decoded.tracks[0].events.length()
  }
  println(
    "iterations=\{iterations} checksum=\{checksum} fixture=four-chord-report-voice-leading-smf",
  )
}
