///|
test "interval parsing and transposition" {
  let c4 = Note::parse("C4").unwrap()

  // Major 3rd Up
  let m3 = Interval::parse("M3").unwrap()
  inspect(c4.transpose(m3).to_string(), content="E4")

  // minor 3rd Up
  let m3_minor = Interval::parse("m3").unwrap()
  inspect(c4.transpose(m3_minor).to_string(), content="Eb4")

  // Perfect 5th Down
  let p5_down = Interval::parse("-P5").unwrap()
  inspect(c4.transpose(p5_down).to_string(), content="F3")

  // Octave Up
  let p8 = Interval::parse("P8").unwrap()
  inspect(c4.transpose(p8).to_string(), content="C5")
}
