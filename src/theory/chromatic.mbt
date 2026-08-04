///|
pub(all) enum AugmentedSixthType {
  Italian
  French
  German
} derive(Eq, Debug)

///|
pub fn AugmentedSixthType::to_string(self : AugmentedSixthType) -> String {
  match self {
    Italian => "Italian"
    French => "French"
    German => "German"
  }
}

///|
pub impl Show for AugmentedSixthType with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn generate_augmented_sixth(
  key : Key,
  type_ : AugmentedSixthType,
) -> Array[Note] {
  // bVI note is the root of Augmented Sixth.
  // We can calculate bVI by transposing key root by minor 6th up (8 semitones).
  let m6 = Interval::new(IntervalQuality::Minor, 6, 8, IntervalDirection::Up)
  let key_root_note = Note::new(key.root, key.accidental, 4)
  let bvi = key_root_note.transpose(m6)

  // 1st degree of the key is the tonic
  let tonic = Note::new(key.root, key.accidental, 4)
  // If tonic is lower than bvi, transpose it up an octave to keep it voiced nicely
  let tonic_voiced = if tonic.to_midi() < bvi.to_midi() {
    let p8 = Interval::new(
      IntervalQuality::Perfect,
      8,
      12,
      IntervalDirection::Up,
    )
    tonic.transpose(p8)
  } else {
    tonic
  }

  // #4 degree of the key: transpose tonic by Augmented 4th (6 semitones)
  let a4 = Interval::new(
    IntervalQuality::Augmented,
    4,
    6,
    IntervalDirection::Up,
  )
  let sharp4 = tonic.transpose(a4)
  let sharp4_voiced = if sharp4.to_midi() < tonic_voiced.to_midi() {
    let p8 = Interval::new(
      IntervalQuality::Perfect,
      8,
      12,
      IntervalDirection::Up,
    )
    sharp4.transpose(p8)
  } else {
    sharp4
  }

  match type_ {
    Italian => [bvi, tonic_voiced, sharp4_voiced]
    French => {
      // Includes scale degree 2 (major second from tonic)
      let m2 = Interval::new(
        IntervalQuality::Major,
        2,
        2,
        IntervalDirection::Up,
      )
      let deg2 = tonic.transpose(m2)
      let deg2_voiced = if deg2.to_midi() < tonic_voiced.to_midi() {
        let p8 = Interval::new(
          IntervalQuality::Perfect,
          8,
          12,
          IntervalDirection::Up,
        )
        deg2.transpose(p8)
      } else {
        deg2
      }

      // Voicing order: bvi, tonic, deg2, sharp4
      [bvi, tonic_voiced, deg2_voiced, sharp4_voiced]
    }
    German => {
      // Includes scale degree b3 (minor third from tonic)
      let m3 = Interval::new(
        IntervalQuality::Minor,
        3,
        3,
        IntervalDirection::Up,
      )
      let deg3 = tonic.transpose(m3)
      let deg3_voiced = if deg3.to_midi() < tonic_voiced.to_midi() {
        let p8 = Interval::new(
          IntervalQuality::Perfect,
          8,
          12,
          IntervalDirection::Up,
        )
        deg3.transpose(p8)
      } else {
        deg3
      }

      // Voicing order: bvi, tonic, deg3, sharp4
      [bvi, tonic_voiced, deg3_voiced, sharp4_voiced]
    }
  }
}

///|
pub fn generate_neapolitan_sixth(key : Key) -> Array[Note] {
  // Neapolitan chord is flat II major triad in 1st inversion.
  // Flat II root is minor second (1 semitone) above key root
  let m2 = Interval::new(IntervalQuality::Minor, 2, 1, IntervalDirection::Up)
  let key_root_note = Note::new(key.root, key.accidental, 4)
  let flat_ii = key_root_note.transpose(m2)

  // Triad notes: flat_ii, major third, perfect fifth
  let triad = generate_chord(flat_ii, ChordType::MajorTriad)

  // Neapolitan sixth is in first inversion, so rotate the first note flat_ii up an octave
  let p8 = Interval::new(IntervalQuality::Perfect, 8, 12, IntervalDirection::Up)
  let f_inv = [triad[1], triad[2], triad[0].transpose(p8)]
  f_inv
}
