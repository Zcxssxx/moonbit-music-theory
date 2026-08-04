///|
fn format_array(arr : Array[String]) -> String {
  let mut res = "["
  for i in 0..<arr.length() {
    if i > 0 {
      res = res + ", "
    }
    res = res + "\"" + arr[i] + "\""
  }
  res = res + "]"
  res
}

///|
test "scale generation" {
  let c4 = Note::parse("C4").unwrap()

  // C Major
  let c_major = generate_scale(c4, ScaleType::Major)
  let c_major_strs = c_major.map(fn(n) { n.to_string() })
  inspect(
    format_array(c_major_strs),
    content="[\"C4\", \"D4\", \"E4\", \"F4\", \"G4\", \"A4\", \"B4\"]",
  )

  // C Minor
  let c_minor = generate_scale(c4, ScaleType::Minor)
  let c_minor_strs = c_minor.map(fn(n) { n.to_string() })
  inspect(
    format_array(c_minor_strs),
    content="[\"C4\", \"D4\", \"Eb4\", \"F4\", \"G4\", \"Ab4\", \"Bb4\"]",
  )
}

///|
test "advanced scale types" {
  let c4 = Note::parse("C4").unwrap()

  // C Melodic Minor
  let c_mel_min = generate_scale(c4, ScaleType::MelodicMinor)
  let c_mel_min_strs = c_mel_min.map(fn(n) { n.to_string() })
  inspect(
    format_array(c_mel_min_strs),
    content="[\"C4\", \"D4\", \"Eb4\", \"F4\", \"G4\", \"A4\", \"B4\"]",
  )

  // C Whole Tone
  let c_wt = generate_scale(c4, ScaleType::WholeTone)
  let c_wt_strs = c_wt.map(fn(n) { n.to_string() })
  inspect(
    format_array(c_wt_strs),
    content="[\"C4\", \"D4\", \"E4\", \"F#4\", \"G#4\", \"A#4\"]",
  )
}

///|
test "scale degrees and parent scale" {
  inspect(scale_degree_name(1), content="Tonic")
  inspect(scale_degree_name(5), content="Dominant")
  inspect(scale_degree_name(7), content="Leading Tone")

  inspect(ScaleType::SuperLocrian.parent_scale(), content="Melodic Minor")
  inspect(
    ScaleType::Dorian.parent_scale(),
    content="Diatonic (Major/Natural Minor)",
  )
}

///|
test "scale common notes" {
  let c4 = Note::parse("C4").unwrap()
  let c_major = generate_scale(c4, ScaleType::Major)
  let g_major = generate_scale(Note::parse("G4").unwrap(), ScaleType::Major)

  let common = scale_common_notes(c_major, g_major)
  let common_strs = common.map(fn(n) { n.to_string() })
  // Common notes between C Major (C D E F G A B) and G Major (G A B C D E F#) are C D E G A B (6 notes)
  inspect(
    format_array(common_strs),
    content="[\"C4\", \"D4\", \"E4\", \"G4\", \"A4\", \"B4\"]",
  )
}

///|
test "scale diatonic chords generation" {
  let c4 = Note::parse("C4").unwrap()

  // Triads of C Major
  let triads = generate_diatonic_chords(c4, ScaleType::Major, 3)
  inspect(triads.length(), content="7")

  // I triad should be C4, E4, G4
  let (lbl1, notes1) = triads[0]
  inspect(lbl1, content="I")
  let notes1_strs = notes1.map(fn(n) { n.to_string() })
  inspect(format_array(notes1_strs), content="[\"C4\", \"E4\", \"G4\"]")

  // ii triad should be D4, F4, A4
  let (lbl2, notes2) = triads[1]
  inspect(lbl2, content="II")
  let notes2_strs = notes2.map(fn(n) { n.to_string() })
  inspect(format_array(notes2_strs), content="[\"D4\", \"F4\", \"A4\"]")

  // vii triad should be B4, D5, F5 (D5 and F5 are transposed up since they wrap)
  let (lbl7, notes7) = triads[6]
  inspect(lbl7, content="VII")
  let notes7_strs = notes7.map(fn(n) { n.to_string() })
  inspect(format_array(notes7_strs), content="[\"B4\", \"D5\", \"F5\"]")
}
