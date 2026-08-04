///|
pub fn to_drop_2(voicing : Array[Note]) -> Array[Note] {
  let len = voicing.length()
  if len < 3 {
    return voicing.map(fn(x) { x })
  }

  let sorted = sort_notes(voicing)
  let drop_idx = len - 2
  let p8 = Interval::new(
    IntervalQuality::Perfect,
    8,
    12,
    IntervalDirection::Down,
  )
  let dropped = sorted[drop_idx].transpose(p8)

  let res = []
  for i in 0..<len {
    if i == drop_idx {
      res.push(dropped)
    } else {
      res.push(sorted[i])
    }
  }
  sort_notes(res)
}

///|
pub fn to_drop_3(voicing : Array[Note]) -> Array[Note] {
  let len = voicing.length()
  if len < 4 {
    return voicing.map(fn(x) { x })
  }

  let sorted = sort_notes(voicing)
  let drop_idx = len - 3
  let p8 = Interval::new(
    IntervalQuality::Perfect,
    8,
    12,
    IntervalDirection::Down,
  )
  let dropped = sorted[drop_idx].transpose(p8)

  let res = []
  for i in 0..<len {
    if i == drop_idx {
      res.push(dropped)
    } else {
      res.push(sorted[i])
    }
  }
  sort_notes(res)
}

///|
pub fn to_open_voicing(voicing : Array[Note]) -> Array[Note] {
  let len = voicing.length()
  if len < 3 {
    return voicing.map(fn(x) { x })
  }

  let sorted = sort_notes(voicing)
  // Drop the second note down an octave, and transpose the highest note up an octave
  let p8_down = Interval::new(
    IntervalQuality::Perfect,
    8,
    12,
    IntervalDirection::Down,
  )
  let p8_up = Interval::new(
    IntervalQuality::Perfect,
    8,
    12,
    IntervalDirection::Up,
  )

  let res = []
  for i in 0..<len {
    if i == 1 {
      res.push(sorted[i].transpose(p8_down))
    } else if i == len - 1 {
      res.push(sorted[i].transpose(p8_up))
    } else {
      res.push(sorted[i])
    }
  }
  sort_notes(res)
}

///|
pub fn check_voicing_spacing(voicing : Array[Note]) -> Array[String] {
  let warnings : Array[String] = []
  let len = voicing.length()
  if len < 3 {
    return warnings
  }

  let sorted = sort_notes(voicing)
  // Check upper voices: from index 1 to len-1
  for i in 1..<(len - 1) {
    let diff = sorted[i + 1].to_midi() - sorted[i].to_midi()
    if diff > 12 {
      let n1 = sorted[i]
      let n2 = sorted[i + 1]
      warnings.push(
        "Spacing warning: Interval between upper voices \{n1} and \{n2} is \{diff} semitones, exceeding one octave.",
      )
    }
  }

  warnings
}
