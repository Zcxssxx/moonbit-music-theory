///|
test "rhythm and duration calculations" {
  let ts_4_4 = TimeSignature::new(4, 4)
  inspect(ts_4_4.to_string(), content="4/4")

  // Quarter note duration in 4/4 is 1.0 beats
  let quarter = NoteDuration::Quarter
  inspect(quarter.to_beats(ts_4_4), content="1")

  // Whole note duration in 4/4 is 4.0 beats
  let whole = NoteDuration::Whole
  inspect(whole.to_beats(ts_4_4), content="4")

  // Eighth note duration in 4/4 is 0.5 beats
  let eighth = NoteDuration::Eighth
  inspect(eighth.to_beats(ts_4_4), content="0.5")

  // Seconds calculation at 120 bpm (1 beat = 0.5 seconds)
  inspect(quarter.to_seconds(ts_4_4, 120.0), content="0.5")
  inspect(whole.to_seconds(ts_4_4, 120.0), content="2")

  // Dotted quarter note (1.5 beats)
  let dotted_q = quarter.dotted(ts_4_4, 1)
  inspect(dotted_q, content="1.5")

  // Triplet eighth note (3 in space of 2 eighth notes -> 2/3 of 0.5 beats = 0.3333333333333333)
  let triplet_e = eighth.tuplet(ts_4_4, 3, 2)
  inspect(triplet_e, content="0.3333333333333333")

  // Ticks conversion with PPQ = 960
  inspect(quarter.to_ticks(960), content="960")
  inspect(eighth.to_ticks(960), content="480")
}
