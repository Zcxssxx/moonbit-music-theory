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

test "scale generation" {
  let c4 = Note::parse("C4").unwrap()

  // C Major
  let c_major = generate_scale(c4, ScaleType::Major)
  let c_major_strs = c_major.map(fn(n) { n.to_string() })
  inspect(format_array(c_major_strs), content="[\"C4\", \"D4\", \"E4\", \"F4\", \"G4\", \"A4\", \"B4\"]")

  // C Minor
  let c_minor = generate_scale(c4, ScaleType::Minor)
  let c_minor_strs = c_minor.map(fn(n) { n.to_string() })
  inspect(format_array(c_minor_strs), content="[\"C4\", \"D4\", \"Eb4\", \"F4\", \"G4\", \"Ab4\", \"Bb4\"]")
}
