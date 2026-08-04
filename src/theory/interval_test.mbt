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

///|
test "interval inversion" {
  let m3 = Interval::parse("M3").unwrap()
  let inv_m3 = m3.invert()
  inspect(inv_m3.to_string(), content="m6")

  let p5 = Interval::parse("P5").unwrap()
  let inv_p5 = p5.invert()
  inspect(inv_p5.to_string(), content="P4")

  let a4 = Interval::parse("A4").unwrap()
  let inv_a4 = a4.invert()
  inspect(inv_a4.to_string(), content="d5")
}

///|
test "interval arithmetic addition and subtraction" {
  let m3 = Interval::parse("M3").unwrap()
  let m3_minor = Interval::parse("m3").unwrap()

  let p5 = m3.add(m3_minor)
  inspect(p5.to_string(), content="P5")

  let sub_res = p5.sub(m3)
  inspect(sub_res.to_string(), content="m3")
}
