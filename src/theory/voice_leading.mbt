///|
pub(all) struct VoiceLeadingOptions {
  lowest_midi : Int
  highest_midi : Int
  max_spacing : Int
} derive(Eq, Debug)

///|
pub fn VoiceLeadingOptions::new(
  lowest_midi~ : Int,
  highest_midi~ : Int,
  max_spacing~ : Int,
) -> VoiceLeadingOptions {
  { lowest_midi, highest_midi, max_spacing }
}

///|
pub fn VoiceLeadingOptions::default() -> VoiceLeadingOptions {
  { lowest_midi: 48, highest_midi: 84, max_spacing: 12 }
}

///|
pub(all) struct VoiceLeadingCost {
  total_semitone_motion : Int
  max_single_voice_motion : Int
  common_tones : Int
  lexicographic_midi : Array[Int]
} derive(Eq, Debug)

///|
pub(all) struct VoiceLeadingResult {
  start_voicing : Array[Note]
  target_voicing : Array[Note]
  voice_movements : Array[Int]
  total_semitone_motion : Int
  max_single_voice_motion : Int
  common_tones : Int
  cost : VoiceLeadingCost
  warnings : Array[CounterpointWarning]
} derive(Eq, Debug)

///|
fn validate_voice_leading_options(
  options : VoiceLeadingOptions,
) -> Unit raise Failure {
  if options.lowest_midi > options.highest_midi {
    fail("lowest MIDI must not exceed highest MIDI")
  }
  if options.max_spacing < 0 {
    fail("max spacing must be non-negative")
  }
}

///|
fn count_common_tones(left : Array[Note], right : Array[Note]) -> Int {
  let right_midis = right.map(fn(note) { note.to_midi() })
  let right_used = right_midis.map(fn(_) { false })
  let mut count = 0
  for note in left {
    let midi = note.to_midi()
    for i in 0..<right_midis.length() {
      if !right_used[i] && midi == right_midis[i] {
        count = count + 1
        right_used[i] = true
        break
      }
    }
  }
  count
}

///|
fn voice_movements_between(
  left : Array[Note],
  right : Array[Note],
) -> Array[Int] {
  let movements : Array[Int] = []
  let min_len = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  for i in 0..<min_len {
    movements.push((right[i].to_midi() - left[i].to_midi()).abs())
  }
  movements
}

///|
fn build_voice_leading_cost(
  start_voicing : Array[Note],
  target_voicing : Array[Note],
) -> VoiceLeadingCost {
  let movements = voice_movements_between(start_voicing, target_voicing)
  let mut raw_total_motion = 0
  let mut max_motion = 0
  for movement in movements {
    raw_total_motion = raw_total_motion + movement
    if movement > max_motion {
      max_motion = movement
    }
  }
  let common_tones = count_common_tones(start_voicing, target_voicing)
  // `voice_movements` preserves the raw per-voice semitone distances.
  // `total_semitone_motion` reports the raw sum with a one-point credit for
  // each exact-MIDI common tone so callers can compare both views directly.
  let total_motion = if raw_total_motion > common_tones {
    raw_total_motion - common_tones
  } else {
    0
  }
  {
    total_semitone_motion: total_motion,
    max_single_voice_motion: max_motion,
    common_tones,
    lexicographic_midi: target_voicing.map(fn(note) { note.to_midi() }),
  }
}

///|
fn compare_int_arrays(left : Array[Int], right : Array[Int]) -> Int {
  let min_len = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  for i in 0..<min_len {
    if left[i] < right[i] {
      return -1
    }
    if left[i] > right[i] {
      return 1
    }
  }
  if left.length() < right.length() {
    -1
  } else if left.length() > right.length() {
    1
  } else {
    0
  }
}

///|
fn prefer_cost(candidate : VoiceLeadingCost, best : VoiceLeadingCost) -> Bool {
  if candidate.total_semitone_motion != best.total_semitone_motion {
    return candidate.total_semitone_motion < best.total_semitone_motion
  }
  if candidate.max_single_voice_motion != best.max_single_voice_motion {
    return candidate.max_single_voice_motion < best.max_single_voice_motion
  }
  if candidate.common_tones != best.common_tones {
    return candidate.common_tones > best.common_tones
  }
  compare_int_arrays(candidate.lexicographic_midi, best.lexicographic_midi) < 0
}

///|
fn chord_tones_covered(
  candidate : Array[Note],
  base_notes : Array[Note],
) -> Bool {
  for base_note in base_notes {
    let pitch_class = (base_note.to_midi() % 12 + 12) % 12
    let mut found = false
    for note in candidate {
      if (note.to_midi() % 12 + 12) % 12 == pitch_class {
        found = true
      }
    }
    if !found {
      return false
    }
  }
  true
}

///|
fn candidate_respects_constraints(
  candidate : Array[Note],
  options : VoiceLeadingOptions,
) -> Bool {
  if candidate.length() == 0 {
    return false
  }

  for note in candidate {
    let midi = note.to_midi()
    if midi < options.lowest_midi || midi > options.highest_midi {
      return false
    }
  }

  for i in 0..<(candidate.length() - 1) {
    let lower = candidate[i].to_midi()
    let upper = candidate[i + 1].to_midi()
    if lower > upper {
      return false
    }
    if upper - lower > options.max_spacing {
      return false
    }
  }

  true
}

///|
fn octave_variants_in_range(
  base_note : Note,
  options : VoiceLeadingOptions,
) -> Array[Note] {
  let variants : Array[Note] = []
  let min_octave = options.lowest_midi / 12 - 2
  let max_octave = options.highest_midi / 12
  for octave in min_octave..<=max_octave {
    let candidate = Note::new(base_note.letter, base_note.accidental, octave)
    let midi = candidate.to_midi()
    if midi >= options.lowest_midi && midi <= options.highest_midi {
      variants.push(candidate)
    }
  }
  variants
}

///|
fn unique_sorted_pool(
  base_notes : Array[Note],
  options : VoiceLeadingOptions,
) -> Array[Note] {
  let pool : Array[Note] = []
  let seen : Map[String, Unit] = Map([])
  for base_note in base_notes {
    for note in octave_variants_in_range(base_note, options) {
      let key = note.to_string()
      if !seen.contains(key) {
        seen[key] = ()
        pool.push(note)
      }
    }
  }
  sort_notes(pool)
}

///|
fn candidate_key(notes : Array[Note]) -> String {
  let mut key = ""
  for i in 0..<notes.length() {
    if i > 0 {
      key = key + "|"
    }
    key = key + notes[i].to_string()
  }
  key
}

///|
fn enumerate_candidates(
  base_notes : Array[Note],
  target_voice_count : Int,
  options : VoiceLeadingOptions,
) -> Array[Array[Note]] {
  let pool = unique_sorted_pool(base_notes, options)
  let candidates : Array[Array[Note]] = []
  let seen : Map[String, Unit] = Map([])

  fn visit(
    remaining : Int,
    start_idx : Int,
    current : Array[Note],
    pool : Array[Note],
    options : VoiceLeadingOptions,
    base_notes : Array[Note],
    candidates : Array[Array[Note]],
    seen : Map[String, Unit],
  ) -> Unit {
    if remaining == 0 {
      if chord_tones_covered(current, base_notes) &&
        candidate_respects_constraints(current, options) {
        let key = candidate_key(current)
        if !seen.contains(key) {
          seen[key] = ()
          candidates.push(current.map(fn(note) { note }))
        }
      }
      return
    }

    for i in start_idx..<pool.length() {
      current.push(pool[i])
      visit(
        remaining - 1,
        i,
        current,
        pool,
        options,
        base_notes,
        candidates,
        seen,
      )
      let _ = current.pop()
    }
  }

  if target_voice_count > 0 && pool.length() > 0 {
    visit(
      target_voice_count,
      0,
      [],
      pool,
      options,
      base_notes,
      candidates,
      seen,
    )
  }
  candidates
}

///|
pub fn solve_voice_leading(
  start_voicing : Array[Note],
  target_root : Note,
  target_type : ChordType,
  options : VoiceLeadingOptions,
) -> VoiceLeadingResult raise Failure {
  validate_voice_leading_options(options)

  let sorted_start = sort_notes(start_voicing)
  let base_notes = generate_chord(target_root, target_type)
  if base_notes.length() == 0 {
    fail("target chord produced no chord tones")
  }

  let mut best_candidate : Array[Note] = []
  let mut best_cost = build_voice_leading_cost([], [])
  let mut found_candidate = false
  let target_voice_count = if sorted_start.length() == 0 {
    base_notes.length()
  } else {
    sorted_start.length()
  }

  for candidate in enumerate_candidates(base_notes, target_voice_count, options) {
    let cost = build_voice_leading_cost(sorted_start, candidate)
    if !found_candidate || prefer_cost(cost, best_cost) {
      best_candidate = candidate
      best_cost = cost
      found_candidate = true
    }
  }

  if !found_candidate {
    fail(
      "no valid voice-leading candidate satisfied the range and spacing constraints",
    )
  }

  let movements = voice_movements_between(sorted_start, best_candidate)
  {
    start_voicing: sorted_start,
    target_voicing: best_candidate,
    voice_movements: movements,
    total_semitone_motion: best_cost.total_semitone_motion,
    max_single_voice_motion: best_cost.max_single_voice_motion,
    common_tones: best_cost.common_tones,
    cost: best_cost,
    warnings: [],
  }
}
