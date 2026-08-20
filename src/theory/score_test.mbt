///|
test "score rejects invalid event timing" {
  try
    NoteEvent::new(
      Note::new(NoteLetter::C, Accidental::Natural, 4),
      -1,
      0,
      100,
      0,
    )
  catch {
    err =>
      inspect(
        err.to_string().contains("start tick must be non-negative"),
        content="true",
      )
  } noraise {
    _ => fail("expected invalid timing error")
  }
}

///|
test "score rejects invalid stretch factors" {
  let score = Score::new(480)
  try score.stretch(0.0) catch {
    err =>
      inspect(
        err.to_string().contains("stretch factor must be greater than zero"),
        content="true",
      )
  } noraise {
    _ => fail("expected invalid stretch factor error")
  }
}

///|
test "score transpose and duration are deterministic" {
  let score = Score::new(480)
  let track = score.add_track("lead")
  track.add_note(
    NoteEvent::new(
      Note::new(NoteLetter::C, Accidental::Natural, 4),
      0,
      480,
      100,
      0,
    ),
  )
  track.add_note(
    NoteEvent::new(
      Note::new(NoteLetter::E, Accidental::Natural, 4),
      480,
      240,
      90,
      0,
    ),
  )
  inspect(score.duration_ticks(), content="720")
  inspect(
    score.transpose(Interval::parse("M3").unwrap()).tracks[0].events[0].note.to_string(),
    content="E4",
  )
}

///|
test "score track stores events by start tick order" {
  let score = Score::new(480)
  let track = score.add_track("ordered")
  track.add_note(NoteEvent::new(Note::parse("G4").unwrap(), 480, 120, 80, 0))
  track.add_note(NoteEvent::new(Note::parse("C4").unwrap(), 0, 240, 70, 0))
  inspect(track.events[0].start_tick, content="0")
  inspect(track.events[1].start_tick, content="480")
}

///|
test "score stretch rejects positive factors that collapse duration to zero" {
  let score = Score::new(480)
  let track = score.add_track("tiny")
  track.add_note(NoteEvent::new(Note::parse("C4").unwrap(), 12, 1, 100, 0))

  try score.stretch(0.1) catch {
    err =>
      inspect(
        err.to_string().contains("would collapse note event duration to zero"),
        content="true",
      )
  } noraise {
    _ => fail("expected collapsed duration error")
  }
}
