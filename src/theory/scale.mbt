///|
pub(all) enum ScaleType {
  Major
  Minor
  Dorian
  Phrygian
  Lydian
  Mixolydian
  Locrian
  PentatonicMajor
  PentatonicMinor
  HarmonicMajor
  HarmonicMinor
  MelodicMinor
  WholeTone
  OctatonicHalfWhole
  OctatonicWholeHalf
  SuperLocrian
  Gypsy
  LydianDominant
  PhrygianDominant
} derive(Eq, Debug)

///|
pub fn ScaleType::to_string(self : ScaleType) -> String {
  match self {
    Major => "major"
    Minor => "minor"
    Dorian => "dorian"
    Phrygian => "phrygian"
    Lydian => "lydian"
    Mixolydian => "mixolydian"
    Locrian => "locrian"
    PentatonicMajor => "pentatonic_major"
    PentatonicMinor => "pentatonic_minor"
    HarmonicMajor => "harmonic_major"
    HarmonicMinor => "harmonic_minor"
    MelodicMinor => "melodic_minor"
    WholeTone => "whole_tone"
    OctatonicHalfWhole => "octatonic_half_whole"
    OctatonicWholeHalf => "octatonic_whole_half"
    SuperLocrian => "super_locrian"
    Gypsy => "gypsy"
    LydianDominant => "lydian_dominant"
    PhrygianDominant => "phrygian_dominant"
  }
}

///|
pub fn ScaleType::parse(str : String) -> Result[ScaleType, String] {
  match str {
    "major" | "Ionian" | "ionian" => Ok(ScaleType::Major)
    "minor" | "Aeolian" | "aeolian" => Ok(ScaleType::Minor)
    "dorian" | "Dorian" => Ok(ScaleType::Dorian)
    "phrygian" | "Phrygian" => Ok(ScaleType::Phrygian)
    "lydian" | "Lydian" => Ok(ScaleType::Lydian)
    "mixolydian" | "Mixolydian" => Ok(ScaleType::Mixolydian)
    "locrian" | "Locrian" => Ok(ScaleType::Locrian)
    "pentatonic_major" | "pentatonic-major" => Ok(ScaleType::PentatonicMajor)
    "pentatonic_minor" | "pentatonic-minor" => Ok(ScaleType::PentatonicMinor)
    "harmonic_major" | "harmonic-major" => Ok(ScaleType::HarmonicMajor)
    "harmonic_minor" | "harmonic-minor" => Ok(ScaleType::HarmonicMinor)
    "melodic_minor" | "melodic-minor" => Ok(ScaleType::MelodicMinor)
    "whole_tone" | "whole-tone" => Ok(ScaleType::WholeTone)
    "octatonic_half_whole" | "octatonic-half-whole" =>
      Ok(ScaleType::OctatonicHalfWhole)
    "octatonic_whole_half" | "octatonic-whole-half" =>
      Ok(ScaleType::OctatonicWholeHalf)
    "super_locrian" | "altered" => Ok(ScaleType::SuperLocrian)
    "gypsy" | "double_harmonic_major" => Ok(ScaleType::Gypsy)
    "lydian_dominant" | "lydian-dominant" => Ok(ScaleType::LydianDominant)
    "phrygian_dominant" | "phrygian-dominant" => Ok(ScaleType::PhrygianDominant)
    _ => Err("Unknown scale type: " + str)
  }
}

///|
pub fn ScaleType::intervals(self : ScaleType) -> Array[Interval] {
  let spec = match self {
    Major => ["P1", "M2", "M3", "P4", "P5", "M6", "M7"]
    Minor => ["P1", "M2", "m3", "P4", "P5", "m6", "m7"]
    Dorian => ["P1", "M2", "m3", "P4", "P5", "M6", "m7"]
    Phrygian => ["P1", "m2", "m3", "P4", "P5", "m6", "m7"]
    Lydian => ["P1", "M2", "M3", "A4", "P5", "M6", "M7"]
    Mixolydian => ["P1", "M2", "M3", "P4", "P5", "M6", "m7"]
    Locrian => ["P1", "m2", "m3", "P4", "d5", "m6", "m7"]
    PentatonicMajor => ["P1", "M2", "M3", "P5", "M6"]
    PentatonicMinor => ["P1", "m3", "P4", "P5", "m7"]
    HarmonicMajor => ["P1", "M2", "M3", "P4", "P5", "m6", "M7"]
    HarmonicMinor => ["P1", "M2", "m3", "P4", "P5", "m6", "M7"]
    MelodicMinor => ["P1", "M2", "m3", "P4", "P5", "M6", "M7"]
    WholeTone => ["P1", "M2", "M3", "A4", "A5", "A6"]
    OctatonicHalfWhole => ["P1", "m2", "m3", "M3", "A4", "P5", "M6", "m7"]
    OctatonicWholeHalf => ["P1", "M2", "m3", "P4", "d5", "m6", "M6", "M7"]
    SuperLocrian => ["P1", "m2", "m3", "d4", "d5", "m6", "m7"]
    Gypsy => ["P1", "m2", "M3", "P4", "P5", "m6", "M7"]
    LydianDominant => ["P1", "M2", "M3", "A4", "P5", "M6", "m7"]
    PhrygianDominant => ["P1", "m2", "M3", "P4", "P5", "m6", "m7"]
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
pub fn generate_scale(root : Note, scale_type : ScaleType) -> Array[Note] {
  let intervals = scale_type.intervals()
  let notes = []
  for inv in intervals {
    notes.push(root.transpose(inv))
  }
  notes
}

///|
pub impl Show for ScaleType with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn scale_degree_name(degree : Int) -> String {
  match degree {
    1 => "Tonic"
    2 => "Supertonic"
    3 => "Mediant"
    4 => "Subdominant"
    5 => "Dominant"
    6 => "Submediant"
    7 => "Leading Tone"
    _ => "Degree " + degree.to_string()
  }
}

///|
pub fn ScaleType::parent_scale(self : ScaleType) -> String {
  match self {
    Major | Dorian | Phrygian | Lydian | Mixolydian | Minor | Locrian =>
      "Diatonic (Major/Natural Minor)"
    HarmonicMinor | PhrygianDominant => "Harmonic Minor"
    HarmonicMajor => "Harmonic Major"
    MelodicMinor | LydianDominant | SuperLocrian => "Melodic Minor"
    WholeTone => "Whole Tone"
    OctatonicHalfWhole | OctatonicWholeHalf => "Octatonic (Diminished)"
    Gypsy => "Double Harmonic"
    PentatonicMajor | PentatonicMinor => "Pentatonic"
  }
}

///|
pub fn scale_common_notes(
  scale1 : Array[Note],
  scale2 : Array[Note],
) -> Array[Note] {
  let common : Array[Note] = []
  for n1 in scale1 {
    let n1_pc = (n1.letter.to_int() + n1.accidental.to_int() % 12 + 12) % 12
    for n2 in scale2 {
      let n2_pc = (n2.letter.to_int() + n2.accidental.to_int() % 12 + 12) % 12
      if n1_pc == n2_pc {
        let mut already_in = false
        for c in common {
          let c_pc = (c.letter.to_int() + c.accidental.to_int() % 12 + 12) % 12
          if c_pc == n1_pc {
            already_in = true
            break
          }
        }
        if !already_in {
          common.push(n1)
        }
      }
    }
  }
  common
}

///|
pub fn generate_diatonic_chords(
  root : Note,
  scale_type : ScaleType,
  notes_count : Int,
) -> Array[(String, Array[Note])] {
  let scale_notes = generate_scale(root, scale_type)
  let len = scale_notes.length()
  let res : Array[(String, Array[Note])] = []
  if len == 0 {
    return res
  }

  let p8 = Interval::new(IntervalQuality::Perfect, 8, 12, IntervalDirection::Up)

  for i in 0..<len {
    let chord_notes : Array[Note] = []
    for step in 0..<notes_count {
      let idx = (i + step * 2) % len
      let raw_note = scale_notes[idx]
      // If we wrapped around, transpose the note up an octave (or compound octave if wrapped multiple times)
      let octaves_to_add = (i + step * 2) / len
      let mut voiced_note = raw_note
      for _o in 0..<octaves_to_add {
        voiced_note = voiced_note.transpose(p8)
      }
      chord_notes.push(voiced_note)
    }

    // Label degree
    let label = match i + 1 {
      1 => "I"
      2 => "II"
      3 => "III"
      4 => "IV"
      5 => "V"
      6 => "VI"
      7 => "VII"
      _ => "Degree " + (i + 1).to_string()
    }

    res.push((label, chord_notes))
  }

  res
}
