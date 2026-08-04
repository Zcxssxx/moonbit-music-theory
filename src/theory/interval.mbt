pub enum IntervalQuality {
  Perfect
  Major
  Minor
  Augmented
  Diminished
} derive(Eq, Debug)

pub enum IntervalDirection {
  Up
  Down
} derive(Eq, Debug)

pub struct Interval {
  quality : IntervalQuality
  number : Int // 1 for Unison, 2 for Second, etc.
  semitones : Int
  direction : IntervalDirection
} derive(Eq, Debug)

pub fn Interval::new(quality : IntervalQuality, number : Int, semitones : Int, direction : IntervalDirection) -> Interval {
  { quality, number, semitones, direction }
}

pub fn IntervalQuality::to_string(self : IntervalQuality) -> String {
  match self {
    Perfect => "P"
    Major => "M"
    Minor => "m"
    Augmented => "A"
    Diminished => "d"
  }
}

pub fn IntervalDirection::to_string(self : IntervalDirection) -> String {
  match self {
    Up => "Up"
    Down => "Down"
  }
}

pub fn Interval::to_string(self : Interval) -> String {
  let q = self.quality.to_string()
  let dir = match self.direction {
    Up => ""
    Down => "-"
  }
  "\{dir}\{q}\{self.number}"
}

pub impl Show for IntervalQuality with fn output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for IntervalDirection with fn output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for Interval with fn output(self, logger) {
  logger.write_string(self.to_string())
}

pub fn Interval::parse(str : String) -> Result[Interval, String] {
  let len = str.length()
  if len < 2 {
    return Err("Invalid interval string")
  }
  let mut idx = 0
  let mut dir = IntervalDirection::Up
  if str[0] == '-' {
    dir = IntervalDirection::Down
    idx = idx + 1
  }

  if idx >= len {
    return Err("Missing quality")
  }

  let q_char = str[idx]
  let quality = match q_char {
    'P' | 'p' => IntervalQuality::Perfect
    'M' => IntervalQuality::Major
    'm' => IntervalQuality::Minor
    'A' | 'a' => IntervalQuality::Augmented
    'd' | 'D' => IntervalQuality::Diminished
    _ => return Err("Invalid quality character")
  }
  idx = idx + 1

  if idx >= len {
    return Err("Missing interval number")
  }

  let mut num = 0
  while idx < len {
    let digit = str[idx].to_int() - '0'.to_int()
    if digit < 0 || digit > 9 {
      return Err("Invalid number character")
    }
    num = num * 10 + digit
    idx = idx + 1
  }

  if num < 1 {
    return Err("Interval number must be at least 1")
  }

  // Determine standard semitones based on number and quality
  let diatonic_semitones = match num {
    1 => 0
    2 => 2
    3 => 4
    4 => 5
    5 => 7
    6 => 9
    7 => 11
    8 => 12
    _ => (num - 1) * 12 / 7 // approximation for compound intervals
  }

  let semitones = match quality {
    Perfect => diatonic_semitones
    Major => diatonic_semitones
    Minor => diatonic_semitones - 1
    Augmented => if num == 1 || num == 4 || num == 5 || num == 8 { diatonic_semitones + 1 } else { diatonic_semitones + 1 }
    Diminished => if num == 1 || num == 4 || num == 5 || num == 8 { diatonic_semitones - 1 } else { diatonic_semitones - 2 }
  }

  Ok({ quality, number: num, semitones, direction: dir })
}

pub fn Note::transpose(self : Note, interval : Interval) -> Note {
  let steps = match interval.direction {
    Up => interval.number - 1
    Down => -(interval.number - 1)
  }
  let base_idx = match self.letter {
    C => 0
    D => 1
    E => 2
    F => 3
    G => 4
    A => 5
    B => 6
  }
  let sum = base_idx + steps
  let octave_change = if sum >= 0 {
    sum / 7
  } else {
    (sum - 6) / 7
  }
  
  let new_letter = match ((sum % 7) + 7) % 7 {
    0 => NoteLetter::C
    1 => NoteLetter::D
    2 => NoteLetter::E
    3 => NoteLetter::F
    4 => NoteLetter::G
    5 => NoteLetter::A
    6 => NoteLetter::B
    _ => NoteLetter::C
  }

  let original_midi = self.to_midi()
  let interval_semitones = match interval.direction {
    Up => interval.semitones
    Down => -interval.semitones
  }
  let desired_midi = original_midi + interval_semitones

  let transposed_natural_note = Note::new(new_letter, Accidental::Natural, self.octave + octave_change)
  let natural_midi = transposed_natural_note.to_midi()
  let diff = desired_midi - natural_midi

  let acc = match diff {
    -1 => Accidental::Flat
    0 => Accidental::Natural
    1 => Accidental::Sharp
    _ => if diff < -1 { Accidental::Flat } else { Accidental::Sharp }
  }

  Note::new(new_letter, acc, self.octave + octave_change)
}
