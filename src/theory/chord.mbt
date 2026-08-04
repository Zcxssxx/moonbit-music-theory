pub(all) enum ChordType {
  MajorTriad
  MinorTriad
  DiminishedTriad
  AugmentedTriad
  MajorSeventh
  DominantSeventh
  MinorSeventh
  HalfDiminishedSeventh
  DiminishedSeventh
} derive(Eq, Debug)

pub fn ChordType::to_string(self : ChordType) -> String {
  match self {
    MajorTriad => "major"
    MinorTriad => "minor"
    DiminishedTriad => "diminished"
    AugmentedTriad => "augmented"
    MajorSeventh => "major_seventh"
    DominantSeventh => "dominant_seventh"
    MinorSeventh => "minor_seventh"
    HalfDiminishedSeventh => "half_diminished_seventh"
    DiminishedSeventh => "diminished_seventh"
  }
}

pub fn ChordType::intervals(self : ChordType) -> Array[Interval] {
  let spec = match self {
    MajorTriad => ["P1", "M3", "P5"]
    MinorTriad => ["P1", "m3", "P5"]
    DiminishedTriad => ["P1", "m3", "d5"]
    AugmentedTriad => ["P1", "M3", "A5"]
    MajorSeventh => ["P1", "M3", "P5", "M7"]
    DominantSeventh => ["P1", "M3", "P5", "m7"]
    MinorSeventh => ["P1", "m3", "P5", "m7"]
    HalfDiminishedSeventh => ["P1", "m3", "d5", "m7"]
    DiminishedSeventh => ["P1", "m3", "d5", "d7"]
  }
  let res = []
  for s in spec {
    match Interval::parse(s) {
      Ok(inv) => res.push(inv)
      Err(_) => ()
    }
  }
  res
}

pub fn generate_chord(root : Note, chord_type : ChordType) -> Array[Note] {
  let intervals = chord_type.intervals()
  let notes = []
  for inv in intervals {
    notes.push(root.transpose(inv))
  }
  notes
}

pub fn parse_chord_symbol(symbol : String) -> Result[(Note, ChordType), String] {
  let len = symbol.length()
  if len == 0 {
    return Err("Empty chord symbol")
  }
  let letter_char = symbol[0]
  let letter = match letter_char {
    'C' | 'c' => NoteLetter::C
    'D' | 'd' => NoteLetter::D
    'E' | 'e' => NoteLetter::E
    'F' | 'f' => NoteLetter::F
    'G' | 'g' => NoteLetter::G
    'A' | 'a' => NoteLetter::A
    'B' | 'b' => NoteLetter::B
    _ => return Err("Invalid root note letter")
  }

  let mut acc = Accidental::Natural
  let mut idx = 1
  if idx < len {
    let c = symbol[idx]
    if c == '#' {
      acc = Accidental::Sharp
      idx = idx + 1
    } else if c == 'b' {
      acc = Accidental::Flat
      idx = idx + 1
    }
  }

  // Parse optional octave
  let mut has_octave = false
  let mut octave_val = 0
  let mut is_neg = false
  let mut temp_idx = idx

  if temp_idx < len && symbol[temp_idx] == '-' {
    is_neg = true
    temp_idx = temp_idx + 1
  }

  let mut parsed_digits = 0
  while temp_idx < len {
    let digit = symbol[temp_idx].to_int() - '0'.to_int()
    if digit >= 0 && digit <= 9 {
      octave_val = octave_val * 10 + digit
      temp_idx = temp_idx + 1
      parsed_digits = parsed_digits + 1
      has_octave = true
    } else {
      break
    }
  }

  // Disambiguation: if the digits go to the end and represent just "7",
  // it is the chord suffix, not the octave.
  if temp_idx == len && has_octave {
    let is_seven = if is_neg {
      false
    } else {
      octave_val == 7
    }
    if is_seven {
      has_octave = false
    }
  }

  let octave = if has_octave {
    idx = temp_idx
    if is_neg { -octave_val } else { octave_val }
  } else {
    4 // default octave
  }

  let root = Note::new(letter, acc, octave)
  let suffix = if idx < len {
    symbol[idx:].to_owned()
  } else {
    ""
  }

  let chord_type = match suffix {
    "" | "maj" | "M" | "major" => ChordType::MajorTriad
    "m" | "min" | "minor" | "-" => ChordType::MinorTriad
    "dim" | "o" => ChordType::DiminishedTriad
    "aug" | "+" => ChordType::AugmentedTriad
    "maj7" | "M7" | "major7" => ChordType::MajorSeventh
    "7" | "dom7" => ChordType::DominantSeventh
    "m7" | "min7" | "-7" => ChordType::MinorSeventh
    "m7b5" | "ø" | "half-dim7" => ChordType::HalfDiminishedSeventh
    "dim7" | "o7" => ChordType::DiminishedSeventh
    _ => return Err("Unknown chord suffix: " + suffix)
  }

  Ok((root, chord_type))
}

pub impl Show for ChordType with fn output(self, logger) {
  logger.write_string(self.to_string())
}
