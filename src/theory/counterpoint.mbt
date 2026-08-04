///|
pub(all) struct CounterpointWarning {
  index : Int
  rule_name : String
  message : String
} derive(Eq, Debug)

///|
pub fn CounterpointWarning::to_string(self : CounterpointWarning) -> String {
  "At index \{self.index} (\{self.rule_name}): \{self.message}"
}

///|
pub impl Show for CounterpointWarning with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
fn get_harmonic_interval_semitones(cp_note : Note, cf_note : Note) -> Int {
  (cp_note.to_midi() - cf_note.to_midi()).abs()
}

///|
fn is_consonant_harmonic(semitones : Int) -> Bool {
  let simple = semitones % 12
  // Consonants: Unison (0), minor 3rd (3), major 3rd (4), perfect 5th (7), minor 6th (8), major 6th (9), octave (0)
  // Compound equivalents are also consonant.
  simple == 0 ||
  simple == 3 ||
  simple == 4 ||
  simple == 7 ||
  simple == 8 ||
  simple == 9
}

///|
fn is_valid_melodic_interval(from : Note, to : Note) -> Bool {
  let diff = (to.to_midi() - from.to_midi()).abs()
  // Permitted melodic leaps: major/minor 2nd (1,2), major/minor 3rd (3,4), perfect 4th (5), perfect 5th (7), minor 6th (8), octave (12)
  diff == 1 ||
  diff == 2 ||
  diff == 3 ||
  diff == 4 ||
  diff == 5 ||
  diff == 7 ||
  diff == 8 ||
  diff == 12
}

///|
pub fn check_first_species(
  cantus_firmus : Array[Note],
  counterpoint : Array[Note],
) -> Array[CounterpointWarning] {
  let warnings : Array[CounterpointWarning] = []
  let len = cantus_firmus.length()

  // Rule 1: Length match
  if len != counterpoint.length() {
    warnings.push({
      index: 0,
      rule_name: "LengthMismatch",
      message: "Cantus firmus and counterpoint must have the same length.",
    })
    return warnings
  }

  if len < 3 {
    warnings.push({
      index: 0,
      rule_name: "TooShort",
      message: "Cantus firmus must be at least 3 notes long.",
    })
    return warnings
  }

  // Determine if counterpoint is above or below cantus firmus
  let mut cp_above = true
  let first_cf = cantus_firmus[0].to_midi()
  let first_cp = counterpoint[0].to_midi()
  if first_cp < first_cf {
    cp_above = false
  }

  // Rule 2: Start interval check
  let start_semitones = get_harmonic_interval_semitones(
    counterpoint[0],
    cantus_firmus[0],
  )
  if cp_above {
    if start_semitones != 0 &&
      start_semitones != 7 &&
      start_semitones != 12 &&
      start_semitones != 19 {
      warnings.push({
        index: 0,
        rule_name: "InvalidStartInterval",
        message: "Start interval must be a perfect unison, fifth, or octave.",
      })
    }
    // If below, fifth is not allowed (unison or octave only)
  } else if start_semitones != 0 && start_semitones != 12 {
    warnings.push({
      index: 0,
      rule_name: "InvalidStartInterval",
      message: "Start interval below cantus firmus must be a unison or octave.",
    })
  }

  // Rule 3: End interval check
  let end_semitones = get_harmonic_interval_semitones(
    counterpoint[len - 1],
    cantus_firmus[len - 1],
  )
  if end_semitones != 0 && end_semitones != 12 {
    warnings.push({
      index: len - 1,
      rule_name: "InvalidEndInterval",
      message: "End interval must be a perfect unison or octave.",
    })
  }

  // Rule 4: Intermediate harmonic intervals
  for i in 1..<(len - 1) {
    let semitones = get_harmonic_interval_semitones(
      counterpoint[i],
      cantus_firmus[i],
    )
    if !is_consonant_harmonic(semitones) {
      warnings.push({
        index: i,
        rule_name: "DissonantHarmonicInterval",
        message: "Harmonic interval of \{semitones} semitones is dissonant (must be consonant).",
      })
    }
    // Perfect fourth is considered dissonant harmonically in two-voice counterpoint!
    if semitones % 12 == 5 {
      warnings.push({
        index: i,
        rule_name: "HarmonicFourthDissonance",
        message: "Perfect fourth is considered dissonant in two-voice counterpoint.",
      })
    }
  }

  // Rule 5: Melodic intervals and leaps
  for i in 0..<(len - 1) {
    if !is_valid_melodic_interval(cantus_firmus[i], cantus_firmus[i + 1]) {
      warnings.push({
        index: i,
        rule_name: "InvalidMelodicIntervalCF",
        message: "Invalid melodic interval in Cantus Firmus between index \{i} and \{i + 1}.",
      })
    }
    if !is_valid_melodic_interval(counterpoint[i], counterpoint[i + 1]) {
      warnings.push({
        index: i,
        rule_name: "InvalidMelodicIntervalCP",
        message: "Invalid melodic interval in Counterpoint between index \{i} and \{i + 1}.",
      })
    }
  }

  // Rule 6: Voice Crossing
  for i in 0..<len {
    let cf_midi = cantus_firmus[i].to_midi()
    let cp_midi = counterpoint[i].to_midi()
    if cp_above && cp_midi < cf_midi {
      warnings.push({
        index: i,
        rule_name: "VoiceCrossing",
        message: "Counterpoint crossed below cantus firmus.",
      })
    } else if !cp_above && cp_midi > cf_midi {
      warnings.push({
        index: i,
        rule_name: "VoiceCrossing",
        message: "Counterpoint crossed above cantus firmus.",
      })
    }
  }

  // Rule 7: Parallel fifths and octaves
  for i in 0..<(len - 1) {
    let semitones1 = get_harmonic_interval_semitones(
      counterpoint[i],
      cantus_firmus[i],
    )
    let semitones2 = get_harmonic_interval_semitones(
      counterpoint[i + 1],
      cantus_firmus[i + 1],
    )

    let is_p5_1 = semitones1 % 12 == 7
    let is_p5_2 = semitones2 % 12 == 7
    let is_p8_1 = semitones1 % 12 == 0 && semitones1 > 0
    let is_p8_2 = semitones2 % 12 == 0 && semitones2 > 0

    if is_p5_1 && is_p5_2 {
      warnings.push({
        index: i + 1,
        rule_name: "ParallelFifths",
        message: "Parallel fifths are forbidden.",
      })
    }
    if is_p8_1 && is_p8_2 {
      warnings.push({
        index: i + 1,
        rule_name: "ParallelOctaves",
        message: "Parallel octaves are forbidden.",
      })
    }
  }

  // Rule 8: Direct (hidden) octaves and fifths
  for i in 0..<(len - 1) {
    let cp_dir = counterpoint[i + 1].to_midi() - counterpoint[i].to_midi()
    let cf_dir = cantus_firmus[i + 1].to_midi() - cantus_firmus[i].to_midi()

    // Direct motion means both voices move in the same direction
    let is_direct_motion = (cp_dir > 0 && cf_dir > 0) ||
      (cp_dir < 0 && cf_dir < 0)

    if is_direct_motion {
      let semitones2 = get_harmonic_interval_semitones(
        counterpoint[i + 1],
        cantus_firmus[i + 1],
      )
      let target_is_perfect = semitones2 % 12 == 0 || semitones2 % 12 == 7

      if target_is_perfect {
        // Forbidden unless upper voice moves by step (step means change of 1 or 2 semitones)
        let upper_voice_leap = if cp_above {
          cp_dir.abs() > 2
        } else {
          cf_dir.abs() > 2
        }

        if upper_voice_leap {
          warnings.push({
            index: i + 1,
            rule_name: "DirectPerfectInterval",
            message: "Direct (hidden) perfect interval is forbidden when upper voice leaps.",
          })
        }
      }
    }
  }

  // Rule 9: Limit parallel thirds and sixths
  let mut parallel_3rd_count = 0
  let mut parallel_6th_count = 0

  for i in 0..<len {
    let semitones = get_harmonic_interval_semitones(
      counterpoint[i],
      cantus_firmus[i],
    )
    let simple = semitones % 12

    if simple == 3 || simple == 4 {
      parallel_3rd_count = parallel_3rd_count + 1
      parallel_6th_count = 0
      if parallel_3rd_count > 3 {
        warnings.push({
          index: i,
          rule_name: "ExcessiveParallelThirds",
          message: "No more than 3 consecutive parallel thirds allowed.",
        })
      }
    } else if simple == 8 || simple == 9 {
      parallel_6th_count = parallel_6th_count + 1
      parallel_3rd_count = 0
      if parallel_6th_count > 3 {
        warnings.push({
          index: i,
          rule_name: "ExcessiveParallelSixths",
          message: "No more than 3 consecutive parallel sixths allowed.",
        })
      }
    } else {
      parallel_3rd_count = 0
      parallel_6th_count = 0
    }
  }

  warnings
}
