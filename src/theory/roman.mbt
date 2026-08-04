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
    MajorTriad | MajorSeventh | DominantSeventh | AugmentedTriad => true
    MinorTriad
    | MinorSeventh
    | DiminishedTriad
    | DiminishedSeventh
    | HalfDiminishedSeventh => false
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
    MajorTriad | MinorTriad => ""
    DiminishedTriad => "°"
    AugmentedTriad => "+"
    MajorSeventh => "maj7"
    DominantSeventh => "7"
    MinorSeventh => "7"
    HalfDiminishedSeventh => "ø7"
    DiminishedSeventh => "o7"
  }

  Ok("\{prefix}\{roman_numeral}\{suffix}")
}
