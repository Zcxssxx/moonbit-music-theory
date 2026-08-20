///|
pub(all) struct RhythmPattern {
  durations : Array[Int]
} derive(Eq, Debug)

///|
pub fn RhythmPattern::new(
  durations : Array[Int],
) -> RhythmPattern raise Failure {
  for duration in durations {
    if duration < 0 {
      fail("rhythm durations must be non-negative")
    }
  }
  { durations: copy_durations(durations) }
}

///|
pub fn RhythmPattern::rotate(
  self : RhythmPattern,
  offset : Int,
) -> RhythmPattern {
  let len = self.durations.length()
  if len == 0 {
    return { durations: [] }
  }

  let normalized = (offset % len + len) % len
  let rotated = []
  for i in 0..<len {
    rotated.push(self.durations[(i + normalized) % len])
  }
  { durations: rotated }
}

///|
pub fn RhythmPattern::reverse(self : RhythmPattern) -> RhythmPattern {
  let len = self.durations.length()
  let reversed = []
  for i in 0..<len {
    reversed.push(self.durations[len - 1 - i])
  }
  { durations: reversed }
}

///|
pub fn RhythmPattern::repeat(
  self : RhythmPattern,
  count : Int,
) -> RhythmPattern raise Failure {
  if count < 0 {
    fail("repeat count must be non-negative")
  }

  let repeated = []
  for _ in 0..<count {
    for duration in self.durations {
      repeated.push(duration)
    }
  }
  { durations: repeated }
}

///|
pub fn RhythmPattern::quantize_tick(
  self : RhythmPattern,
  tick : Int,
  grid : BeatGrid,
  mode : QuantizeMode,
) -> Int raise Failure {
  let span = self.total_ticks()
  if tick < 0 || tick > span {
    fail("tick must lie within the rhythm pattern span")
  }
  grid.quantize_tick(tick, mode)
}

///|
pub fn analyze_syncopation(pattern : RhythmPattern, grid : BeatGrid) -> Int {
  if pattern.durations.length() == 0 || grid.beat_ticks <= 0 {
    return 0
  }

  let mut score = 0
  let mut tick = 0
  for duration in pattern.durations {
    if tick > 0 && tick % grid.beat_ticks != 0 {
      score += syncopation_weight(grid, tick)
    }
    tick += duration
  }
  score
}

///|
fn RhythmPattern::total_ticks(self : RhythmPattern) -> Int {
  let mut total = 0
  for duration in self.durations {
    total += duration
  }
  total
}

///|
fn copy_durations(durations : Array[Int]) -> Array[Int] {
  let copied = []
  for duration in durations {
    copied.push(duration)
  }
  copied
}

///|
fn syncopation_weight(grid : BeatGrid, tick : Int) -> Int {
  let previous_beat = tick / grid.beat_ticks
  beat_strength(grid, previous_beat) + beat_strength(grid, previous_beat + 1)
}

///|
fn beat_strength(grid : BeatGrid, beat_index : Int) -> Int {
  let beats_per_cycle = if grid.time_signature.beat_value == 8 &&
    grid.time_signature.beats % 3 == 0 &&
    grid.time_signature.beats > 3 {
    grid.time_signature.beats / 3
  } else {
    grid.time_signature.beats
  }
  let normalized = (beat_index % beats_per_cycle + beats_per_cycle) %
    beats_per_cycle
  if normalized == 0 {
    4
  } else if beats_per_cycle % 2 == 0 && normalized == beats_per_cycle / 2 {
    3
  } else {
    2
  }
}
