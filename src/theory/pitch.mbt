///|
pub(all) enum NoteLetter {
  C
  D
  E
  F
  G
  A
  B
} derive(Eq, Debug)

///|
pub(all) enum Accidental {
  DoubleFlat
  Flat
  Natural
  Sharp
  DoubleSharp
} derive(Eq, Debug)

///|
pub(all) struct Note {
  letter : NoteLetter
  accidental : Accidental
  octave : Int
} derive(Eq, Debug)

///|
pub fn Note::new(
  letter : NoteLetter,
  accidental : Accidental,
  octave : Int,
) -> Note {
  { letter, accidental, octave }
}

///|
pub fn NoteLetter::to_int(self : NoteLetter) -> Int {
  match self {
    C => 0
    D => 2
    E => 4
    F => 5
    G => 7
    A => 9
    B => 11
  }
}

///|
pub fn NoteLetter::from_int(val : Int) -> NoteLetter {
  match val % 12 {
    0 => C
    2 => D
    4 => E
    5 => F
    7 => G
    9 => A
    11 => B
    _ => C // fallback
  }
}

///|
pub fn Accidental::to_int(self : Accidental) -> Int {
  match self {
    DoubleFlat => -2
    Flat => -1
    Natural => 0
    Sharp => 1
    DoubleSharp => 2
  }
}

///|
pub fn Note::to_midi(self : Note) -> Int {
  let base = self.letter.to_int()
  let acc = self.accidental.to_int()
  (self.octave + 1) * 12 + base + acc
}

///|
pub fn Note::from_midi(midi : Int) -> Note {
  let octave = midi / 12 - 1
  let pc = (midi % 12 + 12) % 12
  let (letter, accidental) = match pc {
    0 => (NoteLetter::C, Accidental::Natural)
    1 => (NoteLetter::C, Accidental::Sharp)
    2 => (NoteLetter::D, Accidental::Natural)
    3 => (NoteLetter::D, Accidental::Sharp)
    4 => (NoteLetter::E, Accidental::Natural)
    5 => (NoteLetter::F, Accidental::Natural)
    6 => (NoteLetter::F, Accidental::Sharp)
    7 => (NoteLetter::G, Accidental::Natural)
    8 => (NoteLetter::G, Accidental::Sharp)
    9 => (NoteLetter::A, Accidental::Natural)
    10 => (NoteLetter::A, Accidental::Sharp)
    11 => (NoteLetter::B, Accidental::Natural)
    _ => (NoteLetter::C, Accidental::Natural)
  }
  { letter, accidental, octave }
}

///|
pub fn NoteLetter::to_string(self : NoteLetter) -> String {
  match self {
    C => "C"
    D => "D"
    E => "E"
    F => "F"
    G => "G"
    A => "A"
    B => "B"
  }
}

///|
pub fn Accidental::to_string(self : Accidental) -> String {
  match self {
    DoubleFlat => "bb"
    Flat => "b"
    Natural => ""
    Sharp => "#"
    DoubleSharp => "##"
  }
}

///|
pub fn Note::to_string(self : Note) -> String {
  let letter_str = self.letter.to_string()
  let acc_str = self.accidental.to_string()
  "\{letter_str}\{acc_str}\{self.octave}"
}

///|
pub impl Show for NoteLetter with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub impl Show for Accidental with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub impl Show for Note with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn Note::parse(str : String) -> Result[Note, String] {
  let len = str.length()
  if len < 2 {
    return Err("Invalid note string")
  }
  let letter_char = str[0]
  let letter = match letter_char {
    'C' | 'c' => NoteLetter::C
    'D' | 'd' => NoteLetter::D
    'E' | 'e' => NoteLetter::E
    'F' | 'f' => NoteLetter::F
    'G' | 'g' => NoteLetter::G
    'A' | 'a' => NoteLetter::A
    'B' | 'b' => NoteLetter::B
    _ => return Err("Invalid note letter")
  }

  let mut acc = Accidental::Natural
  let mut idx = 1
  if idx < len {
    let c1 = str[idx]
    if c1 == '#' || c1 == 's' || c1 == 'S' {
      acc = Accidental::Sharp
      idx = idx + 1
      if idx < len {
        let c2 = str[idx]
        if c2 == '#' || c2 == 's' || c2 == 'S' {
          acc = Accidental::DoubleSharp
          idx = idx + 1
        }
      }
    } else if c1 == 'x' || c1 == 'X' {
      acc = Accidental::DoubleSharp
      idx = idx + 1
    } else if c1 == 'b' || c1 == 'B' {
      acc = Accidental::Flat
      idx = idx + 1
      if idx < len {
        let c2 = str[idx]
        if c2 == 'b' || c2 == 'B' {
          acc = Accidental::DoubleFlat
          idx = idx + 1
        }
      }
    }
  }

  if idx >= len {
    return Err("Missing octave")
  }

  // Parse octave
  let mut oct_val = 0
  let mut is_neg = false
  if str[idx] == '-' {
    is_neg = true
    idx = idx + 1
  }

  if idx >= len {
    return Err("Invalid octave format")
  }

  let mut parsed_digits = 0
  while idx < len {
    let digit = str[idx].to_int() - '0'.to_int()
    if digit < 0 || digit > 9 {
      return Err("Invalid octave character")
    }
    oct_val = oct_val * 10 + digit
    idx = idx + 1
    parsed_digits = parsed_digits + 1
  }

  if parsed_digits == 0 {
    return Err("Invalid octave format")
  }

  let octave = if is_neg { -oct_val } else { oct_val }
  Ok({ letter, accidental: acc, octave })
}

///|
pub fn Note::to_frequency(self : Note, reference_pitch : Double) -> Double {
  let d = self.to_midi().to_double() - 69.0
  reference_pitch * @math.pow(2.0, d / 12.0)
}

///|
pub fn Note::from_frequency(
  frequency : Double,
  reference_pitch : Double,
) -> Note {
  let d = 12.0 * @math.log2(frequency / reference_pitch)
  let midi = (d + 69.0 + 0.5).to_int()
  Note::from_midi(midi)
}
