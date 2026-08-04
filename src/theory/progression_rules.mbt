///|
pub(all) enum ChordFunction {
  Tonic
  Subdominant
  Dominant
  Unknown
} derive(Eq, Debug)

///|
pub fn get_chord_function(roman : String) -> ChordFunction {
  // Strip flats/sharps and suffixes to get base degree
  let len = roman.length()
  if len == 0 {
    return Unknown
  }
  let mut idx = 0
  if roman[idx] == 'b'.to_int().to_uint16() ||
    roman[idx] == '#'.to_int().to_uint16() {
    idx = idx + 1
  }

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
  match degree_str {
    "I" | "i" | "VI" | "vi" | "III" | "iii" => Tonic
    "IV" | "iv" | "II" | "ii" => Subdominant
    "V" | "v" | "VII" | "vii" => Dominant
    _ => Unknown
  }
}

///|
pub fn check_classical_progression(
  progression : Array[String],
) -> Array[String] {
  let warnings : Array[String] = []
  let len = progression.length()
  if len < 2 {
    return warnings
  }

  for i in 0..<(len - 1) {
    let current = progression[i]
    let next = progression[i + 1]

    let func_curr = get_chord_function(current)
    let func_next = get_chord_function(next)

    // Retrogression check: Dominant -> Subdominant is generally forbidden in classical functional harmony
    if func_curr == Dominant && func_next == Subdominant {
      warnings.push(
        "Functional harmony retrogression at index \{i}: Dominant chord '\{current}' followed by Subdominant '\{next}'.",
      )
    }
  }

  warnings
}

///|
fn next_random(seed : Int) -> (Int, Int) {
  // LCG step
  let next_seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
  // return (new_seed, random_value_between_0_and_99)
  (next_seed, next_seed % 100)
}

///|
pub fn generate_classical_progression(
  key : Key,
  length : Int,
  seed : Int,
) -> Array[String] {
  let prog : Array[String] = []
  if length <= 0 {
    return prog
  }

  let is_major = key.scale_type == ScaleType::Major

  // States: 0 = Tonic, 1 = Subdominant, 2 = Dominant
  let mut state = 0
  let mut current_seed = seed

  for _i in 0..<length {
    // Choose specific chord based on state
    let (s, rand_chord) = next_random(current_seed)
    current_seed = s

    let chord_str = match state {
      0 =>
        // Tonic: I or vi
        if rand_chord < 70 {
          if is_major {
            "I"
          } else {
            "i"
          }
        } else if is_major {
          "vi"
        } else {
          "VI"
        }
      1 =>
        // Subdominant: IV or ii
        if rand_chord < 50 {
          if is_major {
            "IV"
          } else {
            "iv"
          }
        } else if is_major {
          "ii"
        } else {
          "ii°"
        }
      _ =>
        // Dominant: V or vii°
        if rand_chord < 80 {
          "V"
        } else if is_major {
          "vii°"
        } else {
          "vii°"
        }
    }

    prog.push(chord_str)

    // Transition to next state
    let (s2, rand_trans) = next_random(current_seed)
    current_seed = s2

    state = match state {
      0 =>
        // Tonic -> Tonic (30%), Subdominant (40%), Dominant (30%)
        if rand_trans < 30 {
          0
        } else if rand_trans < 70 {
          1
        } else {
          2
        }
      1 =>
        // Subdominant -> Subdominant (20%), Dominant (70%), Tonic (10%)
        if rand_trans < 20 {
          1
        } else if rand_trans < 90 {
          2
        } else {
          0
        }
      _ =>
        // Dominant -> Tonic (80%), Tonic/Deceptive vi (20%)
        // Classical dominant almost always resolves to Tonic
        0
    }
  }

  prog
}

///|
pub fn detect_cadence(chord1 : String, chord2 : String) -> String {
  // Strip flats/sharps and suffixes from chord names to analyze simple cadence relations
  let clean1_buf = StringBuilder()
  for i in 0..<chord1.length() {
    let c = chord1[i]
    if c == 'I'.to_int().to_uint16() ||
      c == 'V'.to_int().to_uint16() ||
      c == 'X'.to_int().to_uint16() ||
      c == 'i'.to_int().to_uint16() ||
      c == 'v'.to_int().to_uint16() ||
      c == 'x'.to_int().to_uint16() {
      clean1_buf.write_char(c.to_int().unsafe_to_char())
    }
  }
  let clean1 = clean1_buf.to_string()

  let clean2_buf = StringBuilder()
  for i in 0..<chord2.length() {
    let c = chord2[i]
    if c == 'I'.to_int().to_uint16() ||
      c == 'V'.to_int().to_uint16() ||
      c == 'X'.to_int().to_uint16() ||
      c == 'i'.to_int().to_uint16() ||
      c == 'v'.to_int().to_uint16() ||
      c == 'x'.to_int().to_uint16() {
      clean2_buf.write_char(c.to_int().unsafe_to_char())
    }
  }
  let clean2 = clean2_buf.to_string()

  match (clean1, clean2) {
    ("V", "I") | ("V", "i") => "Authentic Cadence (AC)"
    ("V", "VI") | ("V", "vi") => "Deceptive Cadence (DC)"
    ("IV", "I") | ("iv", "i") | ("IV", "i") | ("iv", "I") =>
      "Plagal Cadence (PC)"
    (_, "V") | (_, "v") => "Half Cadence (HC)"
    _ => "None"
  }
}

///|
pub fn analyze_progression_cadences(
  progression : Array[String],
) -> Array[(Int, String)] {
  let res : Array[(Int, String)] = []
  let len = progression.length()
  if len < 2 {
    return res
  }

  for i in 0..<(len - 1) {
    let cad = detect_cadence(progression[i], progression[i + 1])
    if cad != "None" {
      res.push((i, cad))
    }
  }

  res
}
