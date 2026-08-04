///|
pub fn generate_progression(
  key : Key,
  roman_numerals : Array[String],
) -> Result[Array[Array[Note]], String] {
  let result : Array[Array[Note]] = []
  if roman_numerals.length() == 0 {
    return Ok(result)
  }

  // Resolve first chord
  let first_roman = roman_numerals[0]
  let first_symbol = match key.chord_from_roman(first_roman) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let (first_root, first_type) = match parse_chord_symbol(first_symbol) {
    Ok(val) => val
    Err(e) => return Err(e)
  }
  let first_voicing = generate_chord(first_root, first_type)
  result.push(first_voicing)

  // Resolve subsequent chords using voice leading optimizer
  let mut prev_voicing = first_voicing
  for i in 1..<roman_numerals.length() {
    let roman = roman_numerals[i]
    let symbol = match key.chord_from_roman(roman) {
      Ok(v) => v
      Err(e) => return Err(e)
    }
    let (root, ty) = match parse_chord_symbol(symbol) {
      Ok(val) => val
      Err(e) => return Err(e)
    }
    let optimal = find_optimal_voicing(prev_voicing, root, ty)
    result.push(optimal)
    prev_voicing = optimal
  }

  Ok(result)
}
