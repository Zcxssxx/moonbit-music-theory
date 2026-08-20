///|
test "progression scoring reports invalid input and ambiguity deterministically" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let analysis = analyze_harmony(key, ["Dm7", "G7", "Cmaj7", "F#dim7", "Hmaj7"])
  let score = score_progression_context(analysis)

  inspect(score.total, content="-2")
  inspect(score.explanation, content="ambiguous harmony -1; invalid input -1")
  debug_inspect(
    score.findings,
    content=(
      #|[
      #|  {
      #|    index: 3,
      #|    symbol: "F#dim7",
      #|    kind: Ambiguity,
      #|    detail: "chromatic harmony does not map to a stable function in C major",
      #|  },
      #|  {
      #|    index: 4,
      #|    symbol: "Hmaj7",
      #|    kind: InvalidInput,
      #|    detail: "Invalid root note letter",
      #|  },
      #|]
    ),
  )
}
