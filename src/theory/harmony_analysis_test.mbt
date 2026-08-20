///|
test "harmony analysis explains a predominant dominant tonic path" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let result = analyze_harmony(key, ["Dm7", "G7", "Cmaj7"])
  debug_inspect(result.functions, content="[Predominant, Dominant, Tonic]")
  inspect(classify_cadence_context(result), content="Authentic")
}

///|
test "ambiguous chromatic chords are not forced into a function" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let result = analyze_harmony(key, ["F#dim7"])
  debug_inspect(result.functions, content="[Ambiguous]")
  debug_inspect(
    result.findings,
    content=(
      #|[
      #|  {
      #|    index: 0,
      #|    symbol: "F#dim7",
      #|    kind: Ambiguity,
      #|    detail: "chromatic harmony does not map to a stable function in C major",
      #|  },
      #|]
    ),
  )
}

///|
test "invalid chord symbols produce invalid input findings" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let result = analyze_harmony(key, ["Hmaj7"])
  debug_inspect(result.functions, content="[Ambiguous]")
  debug_inspect(
    result.findings,
    content=(
      #|[
      #|  {
      #|    index: 0,
      #|    symbol: "Hmaj7",
      #|    kind: InvalidInput,
      #|    detail: "Invalid root note letter",
      #|  },
      #|]
    ),
  )
}

///|
test "cadence classification uses only the trailing context window" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)

  inspect(
    classify_cadence_context(analyze_harmony(key, ["G7", "Cmaj7"])),
    content="Authentic",
  )
  inspect(
    classify_cadence_context(analyze_harmony(key, ["F", "C"])),
    content="Plagal",
  )
  inspect(
    classify_cadence_context(analyze_harmony(key, ["G7", "Am"])),
    content="Deceptive",
  )
  inspect(
    classify_cadence_context(analyze_harmony(key, ["C", "G7"])),
    content="Half",
  )
  inspect(
    classify_cadence_context(
      analyze_harmony(key, ["Dm7", "G7", "Cmaj7", "F#dim7"]),
    ),
    content="Undetermined",
  )
  inspect(
    classify_cadence_context(analyze_harmony(key, ["Cmaj7"])),
    content="Undetermined",
  )
}
