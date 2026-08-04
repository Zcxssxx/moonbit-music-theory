///|
test "pitch class set operations" {
  // C major triad C, E, G -> 0, 4, 7
  let c_maj = PitchClassSet::new([0, 4, 7])
  inspect(c_maj.to_string(), content="[0, 4, 7]")

  // Transpose by 2 semitones -> D major triad (2, 6, 9)
  let d_maj = c_maj.transpose(2)
  inspect(d_maj.to_string(), content="[2, 6, 9]")

  // Invert C major triad
  let inverted = c_maj.invert(0)
  inspect(inverted.to_string(), content="[0, 5, 8]") // 0 -> 0, 4 -> 8, 7 -> 5 -> sorted is [0, 5, 8]
}

///|
test "pitch class set normal form and prime form" {
  // A minor triad: A, C, E -> 9, 0, 4
  let a_min = PitchClassSet::new([9, 0, 4])

  // Normal form of [9, 0, 4]
  // Possible rotations:
  // [9, 0, 4] -> span (4 - 9 + 12)%12 = 7. intervals: 9->0 (3), 0->4 (4)
  // [0, 4, 9] -> span (9 - 0 + 12)%12 = 9.
  // [4, 9, 0] -> span (0 - 4 + 12)%12 = 8.
  // So normal form is [9, 0, 4]
  let nf = a_min.normal_form()
  inspect(nf.to_string(), content="[9, 0, 4]")

  // Prime form of a minor triad is [0, 3, 7] (Forte 3-11)
  let pf = a_min.prime_form()
  inspect(pf.to_string(), content="[0, 3, 7]")
}

///|
test "pitch class set interval class vector" {
  // Major/Minor triad has Forte number 3-11, ICV is [0, 0, 1, 1, 1, 0]
  // Intervals in [0, 4, 7]:
  // 0 to 4: 4 (ic 4)
  // 0 to 7: 7 (ic 5)
  // 4 to 7: 3 (ic 3)
  // Total ICV: [0, 0, 1, 1, 1, 0]
  let c_maj = PitchClassSet::new([0, 4, 7])
  let icv = c_maj.interval_class_vector()

  let mut icv_str = "["
  for i in 0..<icv.length() {
    if i > 0 {
      icv_str = icv_str + ", "
    }
    icv_str = icv_str + icv[i].to_string()
  }
  icv_str = icv_str + "]"
  inspect(icv_str, content="[0, 0, 1, 1, 1, 0]")
}
