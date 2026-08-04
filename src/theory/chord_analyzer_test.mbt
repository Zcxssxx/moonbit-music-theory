///|
test "reverse chord analyzer" {
  // C major triad C4, E4, G4 -> C major triad, root position (inversion 0)
  let c_maj = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
  ]
  let res1 = analyze_chord_notes(c_maj).unwrap()
  let (root1, ty1, inv1) = res1
  inspect(root1.to_string(), content="C4")
  inspect(ty1.to_string(), content="major")
  inspect(inv1, content="0")

  // G major triad in 1st inversion: B3, D4, G4 -> G major triad, inversion 1
  let g_maj_1st = [
    Note::parse("B3").unwrap(),
    Note::parse("D4").unwrap(),
    Note::parse("G4").unwrap(),
  ]
  let res2 = analyze_chord_notes(g_maj_1st).unwrap()
  let (root2, ty2, inv2) = res2
  inspect(root2.to_string(), content="G4")
  inspect(ty2.to_string(), content="major")
  inspect(inv2, content="1")

  // C dominant 7th in root position: C4, E4, G4, Bb4
  let c7 = [
    Note::parse("C4").unwrap(),
    Note::parse("E4").unwrap(),
    Note::parse("G4").unwrap(),
    Note::parse("Bb4").unwrap(),
  ]
  let res3 = analyze_chord_notes(c7).unwrap()
  let (root3, ty3, inv3) = res3
  inspect(root3.to_string(), content="C4")
  inspect(ty3.to_string(), content="dominant_seventh")
  inspect(inv3, content="0")
}
