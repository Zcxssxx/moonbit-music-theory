///|
pub(all) struct TimeSignature {
  beats : Int
  beat_value : Int
} derive(Eq, Debug)

///|
pub fn TimeSignature::new(beats : Int, beat_value : Int) -> TimeSignature {
  { beats, beat_value }
}

///|
pub fn TimeSignature::to_string(self : TimeSignature) -> String {
  "\{self.beats}/\{self.beat_value}"
}

///|
pub impl Show for TimeSignature with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub(all) enum NoteDuration {
  DoubleWhole
  Whole
  Half
  Quarter
  Eighth
  Sixteenth
  ThirtySecond
  SixtyFourth
} derive(Eq, Debug)

///|
pub fn NoteDuration::to_string(self : NoteDuration) -> String {
  match self {
    DoubleWhole => "double_whole"
    Whole => "whole"
    Half => "half"
    Quarter => "quarter"
    Eighth => "eighth"
    Sixteenth => "sixteenth"
    ThirtySecond => "thirty_second"
    SixtyFourth => "sixty_fourth"
  }
}

///|
pub impl Show for NoteDuration with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn NoteDuration::to_beats(
  self : NoteDuration,
  time_sig : TimeSignature,
) -> Double {
  // Relative to beat_value. If beat_value is 4 (quarter note is 1 beat):
  // Quarter -> 1.0
  // Whole -> 4.0
  // Half -> 2.0
  // Eighth -> 0.5
  // Sixteenth -> 0.25
  let base_fraction = match self {
    DoubleWhole => 8.0
    Whole => 4.0
    Half => 2.0
    Quarter => 1.0
    Eighth => 0.5
    Sixteenth => 0.25
    ThirtySecond => 0.125
    SixtyFourth => 0.0625
  }

  // Scale based on time signature beat value (normally 4)
  let beat_value_factor = time_sig.beat_value.to_double() / 4.0
  base_fraction * beat_value_factor
}

///|
pub fn NoteDuration::to_seconds(
  self : NoteDuration,
  time_sig : TimeSignature,
  bpm : Double,
) -> Double {
  if bpm <= 0.0 {
    return 0.0
  }
  let beats = self.to_beats(time_sig)
  // 60 seconds per minute / bpm = seconds per beat
  let sec_per_beat = 60.0 / bpm
  beats * sec_per_beat
}

///|
pub fn NoteDuration::dotted(
  self : NoteDuration,
  time_sig : TimeSignature,
  dots : Int,
) -> Double {
  let base_beats = self.to_beats(time_sig)
  if dots <= 0 {
    return base_beats
  }

  let mut total = base_beats
  let mut current_dot_val = base_beats / 2.0
  for i in 0..<dots {
    if i > 0 {
      current_dot_val = current_dot_val / 2.0
    }
    total = total + current_dot_val
  }
  total
}

///|
pub fn NoteDuration::tuplet(
  self : NoteDuration,
  time_sig : TimeSignature,
  num : Int,
  into : Int,
) -> Double {
  if num <= 0 || into <= 0 {
    return 0.0
  }
  let base_beats = self.to_beats(time_sig)
  base_beats * into.to_double() / num.to_double()
}

///|
pub fn NoteDuration::to_ticks(self : NoteDuration, ppq : Int) -> Int {
  // PPQ is ticks per quarter note
  let ticks_per_quarter = ppq.to_double()
  let factor = match self {
    DoubleWhole => 8.0
    Whole => 4.0
    Half => 2.0
    Quarter => 1.0
    Eighth => 0.5
    Sixteenth => 0.25
    ThirtySecond => 0.125
    SixtyFourth => 0.0625
  }
  (ticks_per_quarter * factor + 0.5).to_int()
}
