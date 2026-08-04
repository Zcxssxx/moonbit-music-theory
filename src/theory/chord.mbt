///|
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
  // Extended chords
  MajorNinth
  MinorNinth
  DominantNinth
  MajorEleventh
  MinorEleventh
  DominantEleventh
  MajorThirteenth
  MinorThirteenth
  DominantThirteenth
  // Suspended chords
  SuspendedSecond
  SuspendedFourth
  // Altered chords
  AlteredSeventhSharpNine
  AlteredSeventhFlatNine
  AlteredSeventhFlatFive
} derive(Eq, Debug)

///|
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
    MajorNinth => "major_ninth"
    MinorNinth => "minor_ninth"
    DominantNinth => "dominant_ninth"
    MajorEleventh => "major_eleventh"
    MinorEleventh => "minor_eleventh"
    DominantEleventh => "dominant_eleventh"
    MajorThirteenth => "major_thirteenth"
    MinorThirteenth => "minor_thirteenth"
    DominantThirteenth => "dominant_thirteenth"
    SuspendedSecond => "suspended_second"
    SuspendedFourth => "suspended_fourth"
    AlteredSeventhSharpNine => "altered_seventh_sharp_nine"
    AlteredSeventhFlatNine => "altered_seventh_flat_nine"
    AlteredSeventhFlatFive => "altered_seventh_flat_five"
  }
}

///|
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
    MajorNinth => ["P1", "M3", "P5", "M7", "M9"]
    MinorNinth => ["P1", "m3", "P5", "m7", "M9"]
    DominantNinth => ["P1", "M3", "P5", "m7", "M9"]
    MajorEleventh => ["P1", "M3", "P5", "M7", "M9", "P11"]
    MinorEleventh => ["P1", "m3", "P5", "m7", "M9", "P11"]
    DominantEleventh => ["P1", "M3", "P5", "m7", "M9", "P11"]
    MajorThirteenth => ["P1", "M3", "P5", "M7", "M9", "P11", "M13"]
    MinorThirteenth => ["P1", "m3", "P5", "m7", "M9", "P11", "M13"]
    DominantThirteenth => ["P1", "M3", "P5", "m7", "M9", "P11", "M13"]
    SuspendedSecond => ["P1", "M2", "P5"]
    SuspendedFourth => ["P1", "P4", "P5"]
    AlteredSeventhSharpNine => ["P1", "M3", "P5", "m7", "A9"]
    AlteredSeventhFlatNine => ["P1", "M3", "P5", "m7", "m9"]
    AlteredSeventhFlatFive => ["P1", "M3", "d5", "m7"]
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

///|
pub fn generate_chord(root : Note, chord_type : ChordType) -> Array[Note] {
  let intervals = chord_type.intervals()
  let notes = []
  for inv in intervals {
    notes.push(root.transpose(inv))
  }
  notes
}

///|
pub fn generate_chord_inversion(
  root : Note,
  chord_type : ChordType,
  inversion : Int,
) -> Array[Note] {
  let notes = generate_chord(root, chord_type)
  let len = notes.length()
  if len == 0 {
    return []
  }
  let actual_inv = (inversion % len + len) % len
  let p8 = Interval::new(IntervalQuality::Perfect, 8, 12, IntervalDirection::Up)

  let res = []
  for i in 0..<len {
    let note = notes[(i + actual_inv) % len]
    if i + actual_inv >= len {
      res.push(note.transpose(p8))
    } else {
      res.push(note)
    }
  }
  res
}

///|
pub fn parse_chord_symbol(symbol : String) -> Result[(Note, ChordType), String] {
  // If symbol contains a slash (e.g. C/E), we parse the main chord before the slash
  let parts = symbol.split("/").collect()
  let main_symbol = parts[0].to_owned()

  let len = main_symbol.length()
  if len == 0 {
    return Err("Empty chord symbol")
  }
  let letter_char = main_symbol[0]
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
    let c = main_symbol[idx]
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

  if temp_idx < len && main_symbol[temp_idx] == '-' {
    is_neg = true
    temp_idx = temp_idx + 1
  }

  let mut parsed_digits = 0
  while temp_idx < len {
    let digit = main_symbol[temp_idx].to_int() - '0'.to_int()
    if digit >= 0 && digit <= 9 {
      octave_val = octave_val * 10 + digit
      temp_idx = temp_idx + 1
      parsed_digits = parsed_digits + 1
      has_octave = true
    } else {
      break
    }
  }

  // Disambiguation: if the digits go to the end and represent just "7", "9", "11", "13"
  // it is the chord suffix, not the octave.
  if temp_idx == len && has_octave {
    let is_suffix = if is_neg {
      false
    } else {
      octave_val == 7 || octave_val == 9 || octave_val == 11 || octave_val == 13
    }
    if is_suffix {
      has_octave = false
    }
  }

  let octave = if has_octave {
    idx = temp_idx
    if is_neg {
      -octave_val
    } else {
      octave_val
    }
  } else {
    4 // default octave
  }

  let root = Note::new(letter, acc, octave)
  let suffix = if idx < len { main_symbol[idx:].to_owned() } else { "" }

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
    "maj9" | "M9" | "major9" => ChordType::MajorNinth
    "m9" | "min9" | "minor9" => ChordType::MinorNinth
    "9" | "dom9" => ChordType::DominantNinth
    "maj11" | "M11" => ChordType::MajorEleventh
    "m11" | "min11" => ChordType::MinorEleventh
    "11" | "dom11" => ChordType::DominantEleventh
    "maj13" | "M13" => ChordType::MajorThirteenth
    "m13" | "min13" => ChordType::MinorThirteenth
    "13" | "dom13" => ChordType::DominantThirteenth
    "sus2" => ChordType::SuspendedSecond
    "sus4" | "sus" => ChordType::SuspendedFourth
    "7#9" | "7alt" => ChordType::AlteredSeventhSharpNine
    "7b9" => ChordType::AlteredSeventhFlatNine
    "7b5" => ChordType::AlteredSeventhFlatFive
    _ => return Err("Unknown chord suffix: " + suffix)
  }

  Ok((root, chord_type))
}

///|
pub fn parse_slash_chord(
  symbol : String,
) -> Result[(Note, ChordType, Int), String] {
  let parts = symbol.split("/").collect()
  if parts.length() < 1 {
    return Err("Invalid chord symbol")
  }
  let (root, chord_type) = match parse_chord_symbol(parts[0].to_owned()) {
    Ok(val) => val
    Err(e) => return Err(e)
  }
  if parts.length() == 1 {
    return Ok((root, chord_type, 0))
  }

  // Parse base letter after slash
  let base_str = parts[1].to_owned()
  if base_str.length() == 0 {
    return Err("Empty slash note")
  }
  let base_letter_char = base_str[0]
  let base_letter = match base_letter_char {
    'C' | 'c' => NoteLetter::C
    'D' | 'd' => NoteLetter::D
    'E' | 'e' => NoteLetter::E
    'F' | 'f' => NoteLetter::F
    'G' | 'g' => NoteLetter::G
    'A' | 'a' => NoteLetter::A
    'B' | 'b' => NoteLetter::B
    _ => return Err("Invalid slash note letter")
  }

  // Find which inversion corresponds to this base note in the chord
  let notes = generate_chord(root, chord_type)
  let mut inversion = 0
  for i in 0..<notes.length() {
    if notes[i].letter == base_letter {
      inversion = i
      break
    }
  }
  Ok((root, chord_type, inversion))
}

///|
pub impl Show for ChordType with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
fn sort_notes(notes : Array[Note]) -> Array[Note] {
  let len = notes.length()
  let copy = notes.map(fn(x) { x })
  for i in 0..<len {
    for j in 0..<(len - 1 - i) {
      if copy[j].to_midi() > copy[j + 1].to_midi() {
        let tmp = copy[j]
        copy[j] = copy[j + 1]
        copy[j + 1] = tmp
      }
    }
  }
  copy
}

///|
fn generate_octave_combinations(num_notes : Int) -> Array[Array[Int]] {
  let res = []
  fn helper(current : Array[Int]) -> Unit {
    if current.length() == num_notes {
      res.push(current.map(fn(x) { x }))
      return
    }
    for oct in 3..<=5 { // octaves 3, 4, 5
      current.push(oct)
      helper(current)
      let _ = current.pop()
    }
  }
  helper([])
  res
}

///|
pub fn find_optimal_voicing(
  start_voicing : Array[Note],
  target_root : Note,
  target_type : ChordType,
) -> Array[Note] {
  let base_notes = generate_chord(target_root, target_type)
  let num_notes = base_notes.length()
  if num_notes == 0 {
    return []
  }

  let combos = generate_octave_combinations(num_notes)
  let sorted_start = sort_notes(start_voicing)

  let mut best_voicing = base_notes
  let mut min_dist = 999999

  for o_combo in combos {
    let candidate : Array[Note] = []
    for i in 0..<num_notes {
      let n = base_notes[i]
      candidate.push(Note::new(n.letter, n.accidental, o_combo[i]))
    }

    let sorted_candidate = sort_notes(candidate)
    let mut dist = 0
    let len1 = sorted_start.length()
    let len2 = sorted_candidate.length()
    let min_len = if len1 < len2 { len1 } else { len2 }

    for i in 0..<min_len {
      dist = dist +
        (sorted_start[i].to_midi() - sorted_candidate[i].to_midi()).abs()
    }
    dist = dist + (len1 - len2).abs() * 12

    if dist < min_dist {
      min_dist = dist
      best_voicing = sorted_candidate
    }
  }
  best_voicing
}
