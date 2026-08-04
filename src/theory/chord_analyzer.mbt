///|
fn get_note_pc(n : Note) -> Int {
  let base = n.letter.to_int()
  let acc = n.accidental.to_int()
  (base + acc % 12 + 12) % 12
}

///|
fn get_chord_type_semitones(ty : ChordType) -> Array[Int] {
  match ty {
    MajorTriad => [0, 4, 7]
    MinorTriad => [0, 3, 7]
    DiminishedTriad => [0, 3, 6]
    AugmentedTriad => [0, 4, 8]
    SuspendedSecond => [0, 2, 7]
    SuspendedFourth => [0, 5, 7]
    MajorSeventh => [0, 4, 7, 11]
    DominantSeventh => [0, 4, 7, 10]
    MinorSeventh => [0, 3, 7, 10]
    HalfDiminishedSeventh => [0, 3, 6, 10]
    DiminishedSeventh => [0, 3, 6, 9]
    AlteredSeventhFlatFive => [0, 4, 6, 10]
    MajorNinth => [0, 2, 4, 7, 11]
    MinorNinth => [0, 2, 3, 7, 10]
    DominantNinth => [0, 2, 4, 7, 10]
    MajorEleventh => [0, 2, 4, 5, 7, 11]
    MinorEleventh => [0, 2, 3, 5, 7, 10]
    DominantEleventh => [0, 2, 4, 5, 7, 10]
    MajorThirteenth => [0, 2, 4, 5, 7, 9, 11]
    MinorThirteenth => [0, 2, 3, 5, 7, 9, 10]
    DominantThirteenth => [0, 2, 4, 5, 7, 9, 10]
    AlteredSeventhSharpNine => [0, 3, 4, 7, 10] // A9 = 3
    AlteredSeventhFlatNine => [0, 1, 4, 7, 10] // m9 = 1
  }
}

///|
fn arrays_equal(a : Array[Int], b : Array[Int]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
fn sort_intervals(arr : Array[Int]) -> Array[Int] {
  let len = arr.length()
  let copy = arr.map(fn(x) { x })
  for i in 0..<len {
    for j in 0..<(len - 1 - i) {
      if copy[j] > copy[j + 1] {
        let tmp = copy[j]
        copy[j] = copy[j + 1]
        copy[j + 1] = tmp
      }
    }
  }
  copy
}

///|
pub fn analyze_chord_notes(
  notes : Array[Note],
) -> Result[(Note, ChordType, Int), String] {
  let len = notes.length()
  if len < 3 {
    return Err("A chord must have at least 3 notes")
  }

  let sorted = sort_notes(notes)
  let bass_note = sorted[0]

  // Extract unique pitch classes of input notes
  let input_pcs : Array[Int] = []
  for n in sorted {
    let pc = get_note_pc(n)
    let mut found = false
    for p in input_pcs {
      if p == pc {
        found = true
        break
      }
    }
    if !found {
      input_pcs.push(pc)
    }
  }

  let all_chord_types = [
    ChordType::MajorTriad,
    ChordType::MinorTriad,
    ChordType::DiminishedTriad,
    ChordType::AugmentedTriad,
    ChordType::SuspendedSecond,
    ChordType::SuspendedFourth,
    ChordType::MajorSeventh,
    ChordType::DominantSeventh,
    ChordType::MinorSeventh,
    ChordType::HalfDiminishedSeventh,
    ChordType::DiminishedSeventh,
    ChordType::AlteredSeventhFlatFive,
    ChordType::MajorNinth,
    ChordType::MinorNinth,
    ChordType::DominantNinth,
    ChordType::AlteredSeventhSharpNine,
    ChordType::AlteredSeventhFlatNine,
  ]

  // Try treating each unique note as the root
  for candidate_root in sorted {
    let root_pc = get_note_pc(candidate_root)

    // Calculate intervals relative to this root
    let rel_intervals = input_pcs.map(fn(pc) { (pc - root_pc + 12) % 12 })
    let sorted_rel = sort_intervals(rel_intervals)

    // Check if sorted_rel matches any chord type semitone pattern
    for ty in all_chord_types {
      let pattern = get_chord_type_semitones(ty)
      if arrays_equal(sorted_rel, pattern) {
        // Find inversion by matching bass_note letter to the generated chord notes
        // Default root note in octave 4 for output simplicity
        let root_voiced = Note::new(
          candidate_root.letter,
          candidate_root.accidental,
          4,
        )
        let chord_notes = generate_chord(root_voiced, ty)
        let mut inversion = 0
        for i in 0..<chord_notes.length() {
          if chord_notes[i].letter == bass_note.letter {
            inversion = i
            break
          }
        }
        return Ok((root_voiced, ty, inversion))
      }
    }
  }

  Err("Chord unrecognized")
}
