///|
pub(all) enum TuningSystem {
  EqualTemperament
  Pythagorean
  JustIntonation
  Meantone
} derive(Eq, Debug)

///|
pub fn TuningSystem::to_string(self : TuningSystem) -> String {
  match self {
    EqualTemperament => "equal"
    Pythagorean => "pythagorean"
    JustIntonation => "just"
    Meantone => "meantone"
  }
}

///|
pub impl Show for TuningSystem with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn TuningSystem::parse(str : String) -> Result[TuningSystem, String] {
  match str {
    "equal" | "Equal" | "12-tet" | "12-TET" =>
      Ok(TuningSystem::EqualTemperament)
    "pythagorean" | "Pythagorean" => Ok(TuningSystem::Pythagorean)
    "just" | "Just" | "just-intonation" => Ok(TuningSystem::JustIntonation)
    "meantone" | "Meantone" | "meantone-temperament" =>
      Ok(TuningSystem::Meantone)
    _ => Err("Unknown tuning system: " + str)
  }
}

///|
pub fn Note::frequency_tuned(
  self : Note,
  tuning : TuningSystem,
  reference_a4 : Double,
) -> Double {
  // A4 in 12-TET is reference_a4 (typically 440Hz).
  // First, we calculate the standard C4 frequency under 12-TET.
  let c4_midi = 60
  let a4_midi = 69
  let c4_12tet = reference_a4 *
    @math.pow(2.0, (c4_midi.to_double() - a4_midi.to_double()) / 12.0)

  match tuning {
    EqualTemperament => self.to_frequency(reference_a4)
    Pythagorean => {
      // Ratios relative to C
      let letter_ratio = match self.letter {
        C => 1.0
        D => 9.0 / 8.0
        E => 81.0 / 64.0
        F => 4.0 / 3.0
        G => 3.0 / 2.0
        A => 27.0 / 16.0
        B => 243.0 / 128.0
      }

      // Pythagorean apotome (chromatic semitone) is 2187/2048
      let apotome = 2187.0 / 2048.0
      let acc_multiplier = match self.accidental {
        DoubleFlat => 1.0 / (apotome * apotome)
        Flat => 1.0 / apotome
        Natural => 1.0
        Sharp => apotome
        DoubleSharp => apotome * apotome
      }

      let octave_multiplier = @math.pow(2.0, (self.octave - 4).to_double())
      c4_12tet * letter_ratio * acc_multiplier * octave_multiplier
    }
    JustIntonation => {
      // 5-limit Just Intonation ratios relative to C
      let letter_ratio = match self.letter {
        C => 1.0
        D => 9.0 / 8.0
        E => 5.0 / 4.0
        F => 4.0 / 3.0
        G => 3.0 / 2.0
        A => 5.0 / 3.0
        B => 15.0 / 8.0
      }

      // Semitone ratio (e.g. major diatonic semitone 16/15, or chromatic semitone 25/24)
      // We use 25/24 as the standard chromatic semitone multiplier for sharps/flats
      let semitone = 25.0 / 24.0
      let acc_multiplier = match self.accidental {
        DoubleFlat => 1.0 / (semitone * semitone)
        Flat => 1.0 / semitone
        Natural => 1.0
        Sharp => semitone
        DoubleSharp => semitone * semitone
      }

      let octave_multiplier = @math.pow(2.0, (self.octave - 4).to_double())
      c4_12tet * letter_ratio * acc_multiplier * octave_multiplier
    }
    Meantone => {
      // 1/4-comma meantone ratios relative to C
      // Pure major third is 5/4 = 1.25. Fifth is 5^(1/4) = 1.495349
      let letter_ratio = match self.letter {
        C => 1.0
        D => @math.pow(5.0, 0.5) / 2.0 // sqrt(5)/2
        E => 5.0 / 4.0 // 1.25
        F => 4.0 / 3.0 * 1.0031 // approx
        G => @math.pow(5.0, 0.25) // 5^(1/4)
        A => @math.pow(5.0, 0.75) / 2.0
        B => 5.0 / 4.0 * @math.pow(5.0, 0.25)
      }

      // Diatonic semitone ratio in meantone is ~1.069984
      let semitone = 1.069984
      let acc_multiplier = match self.accidental {
        DoubleFlat => 1.0 / (semitone * semitone)
        Flat => 1.0 / semitone
        Natural => 1.0
        Sharp => semitone
        DoubleSharp => semitone * semitone
      }

      let octave_multiplier = @math.pow(2.0, (self.octave - 4).to_double())
      c4_12tet * letter_ratio * acc_multiplier * octave_multiplier
    }
  }
}
