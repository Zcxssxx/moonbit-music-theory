///|
pub(all) struct Key {
  root : NoteLetter
  accidental : Accidental
  scale_type : ScaleType
} derive(Eq, Debug)

///|
pub fn Key::new(
  root : NoteLetter,
  accidental : Accidental,
  scale_type : ScaleType,
) -> Key {
  { root, accidental, scale_type }
}

///|
pub fn Key::to_string(self : Key) -> String {
  let root_str = self.root.to_string()
  let acc_str = self.accidental.to_string()
  let type_str = self.scale_type.to_string()
  "\{root_str}\{acc_str} \{type_str}"
}

///|
pub impl Show for Key with fn output(self, logger) {
  logger.write_string(self.to_string())
}

// Generate the 7 diatonic notes of the key

///|
pub fn Key::diatonic_notes(self : Key) -> Array[Note] {
  let root_note = Note::new(self.root, self.accidental, 4)
  generate_scale(root_note, self.scale_type)
}

///|
pub fn Key::analyze_chord(
  self : Key,
  chord_symbol : String,
) -> Result[String, String] {
  let (chord_root, chord_type) = match parse_chord_symbol(chord_symbol) {
    Ok(val) => val
    Err(e) => return Err(e)
  }
  let scale_notes = self.diatonic_notes()
  if scale_notes.length() < 7 {
    return Err("Invalid scale generated for key")
  }

  let key_root_idx = match self.root {
    C => 0
    D => 1
    E => 2
    F => 3
    G => 4
    A => 5
    B => 6
  }

  let chord_root_letter_idx = match chord_root.letter {
    C => 0
    D => 1
    E => 2
    F => 3
    G => 4
    A => 5
    B => 6
  }

  let dist = (chord_root_letter_idx - key_root_idx) % 7
  let degree_num = (if dist < 0 { dist + 7 } else { dist }) + 1

  // Find the scale note with the same letter
  let mut scale_note_opt : Note? = None
  for note in scale_notes {
    if note.letter == chord_root.letter {
      scale_note_opt = Some(note)
      break
    }
  }

  if scale_note_opt is None {
    return Err("Diatonic note for degree not found")
  }
  let scale_note = scale_note_opt.unwrap()

  let chord_acc_val = chord_root.accidental.to_int()
  let scale_acc_val = scale_note.accidental.to_int()
  let diff = chord_acc_val - scale_acc_val

  let prefix = match diff {
    -1 => "b"
    1 => "#"
    _ => if diff < -1 { "b" } else if diff > 1 { "#" } else { "" }
  }

  let is_uppercase = match chord_type {
    MajorTriad
    | MajorSeventh
    | DominantSeventh
    | AugmentedTriad
    | MajorNinth
    | DominantNinth
    | MajorEleventh
    | DominantEleventh
    | MajorThirteenth
    | DominantThirteenth
    | SuspendedSecond
    | SuspendedFourth
    | AlteredSeventhSharpNine
    | AlteredSeventhFlatNine
    | AlteredSeventhFlatFive => true
    MinorTriad
    | MinorSeventh
    | DiminishedTriad
    | DiminishedSeventh
    | HalfDiminishedSeventh
    | MinorNinth
    | MinorEleventh
    | MinorThirteenth => false
  }

  let roman_numeral = if is_uppercase {
    match degree_num {
      1 => "I"
      2 => "II"
      3 => "III"
      4 => "IV"
      5 => "V"
      6 => "VI"
      7 => "VII"
      _ => ""
    }
  } else {
    match degree_num {
      1 => "i"
      2 => "ii"
      3 => "iii"
      4 => "iv"
      5 => "v"
      6 => "vi"
      7 => "vii"
      _ => ""
    }
  }

  let suffix = match chord_type {
    MajorTriad | MinorTriad | SuspendedSecond | SuspendedFourth => ""
    DiminishedTriad => "°"
    AugmentedTriad => "+"
    MajorSeventh => "maj7"
    DominantSeventh | MinorSeventh => "7"
    HalfDiminishedSeventh => "ø7"
    DiminishedSeventh => "o7"
    MajorNinth => "maj9"
    MinorNinth => "m9"
    DominantNinth => "9"
    MajorEleventh => "maj11"
    MinorEleventh => "m11"
    DominantEleventh => "11"
    MajorThirteenth => "maj13"
    MinorThirteenth => "m13"
    DominantThirteenth => "13"
    AlteredSeventhSharpNine => "7#9"
    AlteredSeventhFlatNine => "7b9"
    AlteredSeventhFlatFive => "7b5"
  }

  Ok("\{prefix}\{roman_numeral}\{suffix}")
}

///|
pub fn Key::sharps_or_flats(self : Key) -> (Int, Accidental) {
  // Convert key to its major equivalent for signature purposes
  let major_root_letter = match self.scale_type {
    Major => self.root
    _ => {
      // Minor is 3 semitones below its relative major.
      // Relative major of A minor is C major.
      // Let's transpose root by minor 3rd up!
      let m3 = Interval::new(
        IntervalQuality::Minor,
        3,
        3,
        IntervalDirection::Up,
      )
      let temp_note = Note::new(self.root, self.accidental, 4)
      let rel_maj = temp_note.transpose(m3)
      rel_maj.letter
    }
  }

  let major_root_acc = match self.scale_type {
    Major => self.accidental
    _ => {
      let m3 = Interval::new(
        IntervalQuality::Minor,
        3,
        3,
        IntervalDirection::Up,
      )
      let temp_note = Note::new(self.root, self.accidental, 4)
      let rel_maj = temp_note.transpose(m3)
      rel_maj.accidental
    }
  }

  // Match major key signature
  match (major_root_letter, major_root_acc) {
    (C, Natural) => (0, Accidental::Natural)
    (G, Natural) => (1, Accidental::Sharp)
    (D, Natural) => (2, Accidental::Sharp)
    (A, Natural) => (3, Accidental::Sharp)
    (E, Natural) => (4, Accidental::Sharp)
    (B, Natural) => (5, Accidental::Sharp)
    (F, Sharp) => (6, Accidental::Sharp)
    (C, Sharp) => (7, Accidental::Sharp)
    (F, Natural) => (1, Accidental::Flat)
    (B, Flat) => (2, Accidental::Flat)
    (E, Flat) => (3, Accidental::Flat)
    (A, Flat) => (4, Accidental::Flat)
    (D, Flat) => (5, Accidental::Flat)
    (G, Flat) => (6, Accidental::Flat)
    (C, Flat) => (7, Accidental::Flat)
    _ => (0, Accidental::Natural) // fallback
  }
}

///|
pub fn Key::chord_from_roman(
  self : Key,
  roman : String,
) -> Result[String, String] {
  let len = roman.length()
  if len == 0 {
    return Err("Empty roman numeral")
  }
  let mut idx = 0
  let mut acc_offset = 0

  // Read prefix b or #
  if roman[idx] == 'b' {
    acc_offset = -1
    idx = idx + 1
  } else if roman[idx] == '#' {
    acc_offset = 1
    idx = idx + 1
  }

  if idx >= len {
    return Err("Missing degree")
  }

  // Read Roman numeral letters (I, V, X, i, v, x)
  let degree_buf = StringBuilder()
  while idx < len {
    let c = roman[idx]
    if c == 'I'.to_int().to_uint16() ||
      c == 'V'.to_int().to_uint16() ||
      c == 'X'.to_int().to_uint16() ||
      c == 'i'.to_int().to_uint16() ||
      c == 'v'.to_int().to_uint16() ||
      c == 'x'.to_int().to_uint16() {
      degree_buf.write_char(c.to_int().unsafe_to_char())
      idx = idx + 1
    } else {
      break
    }
  }
  let degree_str = degree_buf.to_string()

  if degree_str.length() == 0 {
    return Err("Invalid degree format")
  }

  let (degree_num, is_uppercase) = match degree_str {
    "I" => (1, true)
    "II" => (2, true)
    "III" => (3, true)
    "IV" => (4, true)
    "V" => (5, true)
    "VI" => (6, true)
    "VII" => (7, true)
    "i" => (1, false)
    "ii" => (2, false)
    "iii" => (3, false)
    "iv" => (4, false)
    "v" => (5, false)
    "vi" => (6, false)
    "vii" => (7, false)
    _ => return Err("Unknown degree: " + degree_str)
  }

  let suffix = if idx < len { roman[idx:].to_owned() } else { "" }

  // Get scale notes to find the diatonic note for this degree
  let diatonic_notes = self.diatonic_notes()
  if degree_num < 1 || degree_num > diatonic_notes.length() {
    return Err("Degree out of range")
  }
  let base_note = diatonic_notes[degree_num - 1]

  // Apply offset to accidental
  let new_acc_val = base_note.accidental.to_int() + acc_offset
  let new_acc = match new_acc_val {
    -2 => Accidental::DoubleFlat
    -1 => Accidental::Flat
    0 => Accidental::Natural
    1 => Accidental::Sharp
    2 => Accidental::DoubleSharp
    _ =>
      if new_acc_val < -2 {
        Accidental::DoubleFlat
      } else {
        Accidental::DoubleSharp
      }
  }

  let root_note = Note::new(base_note.letter, new_acc, 4)

  // Determine chord type suffix to attach
  let chord_suffix = match suffix {
    "" => if is_uppercase { "" } else { "m" }
    "°" | "dim" => "dim"
    "+" | "aug" => "aug"
    "maj7" | "M7" => "maj7"
    "7" => if is_uppercase { "7" } else { "m7" }
    "ø7" | "m7b5" => "m7b5"
    "o7" | "dim7" => "dim7"
    _ => suffix // fallback
  }

  // Return the chord symbol (without octave suffix like 4)
  let root_str = Note::new(root_note.letter, root_note.accidental, 4).to_string()
  let stripped_root = root_str[0:root_str.length() - 1].to_owned()
  Ok(stripped_root + chord_suffix)
}

///|
pub fn Key::relative_minor(self : Key) -> Result[Key, String] {
  if self.scale_type == ScaleType::Major {
    let m3 = Interval::new(
      IntervalQuality::Minor,
      3,
      3,
      IntervalDirection::Down,
    )
    let temp_note = Note::new(self.root, self.accidental, 4)
    let rel = temp_note.transpose(m3)
    Ok(Key::new(rel.letter, rel.accidental, ScaleType::Minor))
  } else {
    Err("Relative minor only defined for Major keys")
  }
}

///|
pub fn Key::relative_major(self : Key) -> Result[Key, String] {
  if self.scale_type == ScaleType::Minor {
    let m3 = Interval::new(IntervalQuality::Minor, 3, 3, IntervalDirection::Up)
    let temp_note = Note::new(self.root, self.accidental, 4)
    let rel = temp_note.transpose(m3)
    Ok(Key::new(rel.letter, rel.accidental, ScaleType::Major))
  } else {
    Err("Relative major only defined for Minor keys")
  }
}

///|
pub fn Key::parallel_key(self : Key) -> Key {
  let new_type = match self.scale_type {
    Major => ScaleType::Minor
    _ => ScaleType::Major
  }
  Key::new(self.root, self.accidental, new_type)
}
