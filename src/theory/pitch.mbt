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
  Flat
  Natural
  Sharp
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
    Flat => -1
    Natural => 0
    Sharp => 1
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
  let pc = midi % 12
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
    Flat => "b"
    Natural => ""
    Sharp => "#"
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
    let c = str[idx]
    if c == '#' || c == 's' || c == 'S' {
      acc = Accidental::Sharp
      idx = idx + 1
    } else if c == 'b' || c == 'B' {
      acc = Accidental::Flat
      idx = idx + 1
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
