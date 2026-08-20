///|
pub(all) enum QuantizeMode {
  Floor
  Ceiling
  HalfUp
} derive(Eq, Debug)

///|
pub(all) struct BeatGrid {
  ppq : Int
  subdivision : Int
  time_signature : TimeSignature
  step_ticks : Int
  beat_ticks : Int
} derive(Eq, Debug)

///|
pub fn BeatGrid::new(
  ppq~ : Int,
  subdivision~ : Int,
  time_signature? : TimeSignature = TimeSignature::new(4, 4),
) -> BeatGrid raise Failure {
  if ppq <= 0 {
    fail("ppq must be positive")
  }
  if subdivision <= 0 {
    fail("subdivision must be positive")
  }

  validate_time_signature(time_signature)
  let step_ticks = compute_step_ticks(ppq, subdivision)
  let beat_ticks = compute_beat_ticks(ppq, time_signature)

  { ppq, subdivision, time_signature, step_ticks, beat_ticks }
}

///|
pub fn BeatGrid::quantize_tick(
  self : BeatGrid,
  tick : Int,
  mode : QuantizeMode,
) -> Int raise Failure {
  if tick < 0 {
    fail("tick must be non-negative")
  }

  let lower = tick / self.step_ticks * self.step_ticks
  let remainder = tick % self.step_ticks
  let upper = if remainder == 0 { lower } else { lower + self.step_ticks }

  match mode {
    Floor => lower
    Ceiling => upper
    HalfUp => if remainder * 2 < self.step_ticks { lower } else { upper }
  }
}

///|
fn compute_step_ticks(ppq : Int, subdivision : Int) -> Int raise Failure {
  let whole_ticks = NoteDuration::Whole.to_ticks(ppq)
  let denominator = subdivision * 2
  if whole_ticks % denominator != 0 {
    fail("subdivision does not divide evenly into ticks")
  }
  whole_ticks / denominator
}

///|
fn compute_beat_ticks(
  ppq : Int,
  time_signature : TimeSignature,
) -> Int raise Failure {
  let whole_ticks = NoteDuration::Whole.to_ticks(ppq)
  if is_compound_meter(time_signature) {
    let numerator = whole_ticks * 3
    if numerator % 8 != 0 {
      fail("time signature beat geometry does not divide evenly into ticks")
    }
    numerator / 8
  } else {
    if whole_ticks % time_signature.beat_value != 0 {
      fail("time signature beat geometry does not divide evenly into ticks")
    }
    whole_ticks / time_signature.beat_value
  }
}

///|
fn validate_time_signature(
  time_signature : TimeSignature,
) -> Unit raise Failure {
  if time_signature.beats <= 0 {
    fail("time signature beats must be positive")
  }
  if time_signature.beat_value <= 0 ||
    !is_power_of_two(time_signature.beat_value) {
    fail("time signature beat value must be a positive power of two")
  }
  if !is_simple_meter(time_signature) && !is_compound_meter(time_signature) {
    fail("unsupported time signature beat geometry")
  }
}

///|
fn is_simple_meter(time_signature : TimeSignature) -> Bool {
  match time_signature.beats {
    2 | 3 | 4 => true
    _ => false
  }
}

///|
fn is_compound_meter(time_signature : TimeSignature) -> Bool {
  time_signature.beat_value == 8 &&
  time_signature.beats >= 6 &&
  time_signature.beats % 3 == 0
}

///|
fn is_power_of_two(value : Int) -> Bool {
  if value <= 0 {
    return false
  }

  let mut current = value
  while current % 2 == 0 {
    current = current / 2
  }
  current == 1
}
