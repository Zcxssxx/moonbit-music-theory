///|
test "rhythm pattern rejects invalid durations" {
  try RhythmPattern::new([0, 240, -1]) catch {
    err =>
      inspect(
        err.to_string().contains("rhythm durations must be non-negative"),
        content="true",
      )
  } noraise {
    _ => fail("expected invalid rhythm error")
  }
}

///|
test "rhythm pattern rotations use normalized offsets" {
  let pattern = RhythmPattern::new([120, 240, 360])
  let rotated = pattern.rotate(4)
  inspect(rotated.durations[0], content="240")
  inspect(rotated.durations[1], content="360")
  inspect(rotated.durations[2], content="120")

  let rotated_back = pattern.rotate(-1)
  inspect(rotated_back.durations[0], content="360")
  inspect(rotated_back.durations[1], content="120")
  inspect(rotated_back.durations[2], content="240")
}

///|
test "rhythm pattern reverse preserves pattern length" {
  let pattern = RhythmPattern::new([120, 240, 360, 480])
  let reversed = pattern.reverse()
  inspect(reversed.durations.length(), content="4")
  inspect(reversed.durations[0], content="480")
  inspect(reversed.durations[1], content="360")
  inspect(reversed.durations[2], content="240")
  inspect(reversed.durations[3], content="120")
}

///|
test "rhythm pattern repetition rejects negative counts" {
  let pattern = RhythmPattern::new([120, 240])

  try pattern.repeat(-1) catch {
    err =>
      inspect(
        err.to_string().contains("repeat count must be non-negative"),
        content="true",
      )
  } noraise {
    _ => fail("expected invalid repeat error")
  }

  let repeated = pattern.repeat(3)
  inspect(repeated.durations.length(), content="6")
  inspect(repeated.durations[0], content="120")
  inspect(repeated.durations[1], content="240")
  inspect(repeated.durations[2], content="120")
  inspect(repeated.durations[3], content="240")
  inspect(repeated.durations[4], content="120")
  inspect(repeated.durations[5], content="240")
}

///|
test "rhythm pattern quantize tick uses pattern span" {
  let grid = BeatGrid::new(ppq=480, subdivision=4)
  let pattern = RhythmPattern::new([480, 240, 240])

  inspect(pattern.quantize_tick(360, grid, QuantizeMode::HalfUp), content="480")
  inspect(pattern.quantize_tick(721, grid, QuantizeMode::Floor), content="720")

  try pattern.quantize_tick(961, grid, QuantizeMode::HalfUp) catch {
    err =>
      inspect(
        err.to_string().contains("tick must lie within the rhythm pattern span"),
        content="true",
      )
  } noraise {
    _ => fail("expected out-of-span quantize error")
  }
}

///|
test "syncopation scores off-beat attacks deterministically" {
  let grid = BeatGrid::new(ppq=480, subdivision=4)
  let straight = RhythmPattern::new([480, 480, 480, 480])
  let syncopated = RhythmPattern::new([
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
  ])

  inspect(analyze_syncopation(straight, grid), content="0")
  inspect(analyze_syncopation(syncopated, grid), content="22")
}

///|
test "syncopation handles compound meter deterministically" {
  let grid = BeatGrid::new(
    ppq=480,
    subdivision=4,
    time_signature=TimeSignature::new(6, 8),
  )
  let straight = RhythmPattern::new([720, 720])
  let syncopated = RhythmPattern::new([
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
    NoteDuration::Eighth.to_ticks(480),
  ])

  inspect(analyze_syncopation(straight, grid), content="0")
  inspect(analyze_syncopation(syncopated, grid), content="28")
}
