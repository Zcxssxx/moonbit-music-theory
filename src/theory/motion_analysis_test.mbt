///|
test "motion analysis classifies parallel motion" {
  let motion = classify_voice_motion(
    lower_start=Some(Note::parse("C4").unwrap()),
    lower_end=Some(Note::parse("D4").unwrap()),
    upper_start=Some(Note::parse("G4").unwrap()),
    upper_end=Some(Note::parse("A4").unwrap()),
  )
  inspect(motion, content="Parallel")
}

///|
test "motion analysis classifies contrary motion" {
  let motion = classify_voice_motion(
    lower_start=Some(Note::parse("C4").unwrap()),
    lower_end=Some(Note::parse("D4").unwrap()),
    upper_start=Some(Note::parse("G4").unwrap()),
    upper_end=Some(Note::parse("F4").unwrap()),
  )
  inspect(motion, content="Contrary")
}

///|
test "motion analysis classifies oblique motion" {
  let motion = classify_voice_motion(
    lower_start=Some(Note::parse("C4").unwrap()),
    lower_end=Some(Note::parse("C4").unwrap()),
    upper_start=Some(Note::parse("G4").unwrap()),
    upper_end=Some(Note::parse("A4").unwrap()),
  )
  inspect(motion, content="Oblique")
}

///|
test "motion analysis classifies similar motion when the interval changes" {
  let motion = classify_voice_motion(
    lower_start=Some(Note::parse("C4").unwrap()),
    lower_end=Some(Note::parse("D4").unwrap()),
    upper_start=Some(Note::parse("E4").unwrap()),
    upper_end=Some(Note::parse("G4").unwrap()),
  )
  inspect(motion, content="Similar")
}

///|
test "motion analysis treats missing voices explicitly" {
  let motion = classify_voice_motion(
    lower_start=None,
    lower_end=Some(Note::parse("C4").unwrap()),
    upper_start=Some(Note::parse("G4").unwrap()),
    upper_end=Some(Note::parse("A4").unwrap()),
  )
  inspect(motion, content="MissingVoice")
}
