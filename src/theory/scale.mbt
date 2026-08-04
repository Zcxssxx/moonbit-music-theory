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
