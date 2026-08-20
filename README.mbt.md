# moonbit-music-theory

A lightweight, zero-dependency, pure algebraic and computational music theory library written in MoonBit. It is designed for composing, education, and music application development.

## Features

- **Notes & Pitch**: Parsing of note names (e.g. `C4`, `F#3`, `Bb-1`) and bidirectionally converting them to MIDI pitch numbers.
- **Intervals**: Algebraic addition, subtraction, and note transposition.
- **Scales & Modes**: Diatonic scale generation for Major, Minor, Dorian, Phrygian, Lydian, Mixolydian, and Locrian scales, as well as Pentatonic scales.
- **Chords**: Generation of triads and seventh chords from a root note, and parsing standard chord symbols (e.g. `Cmaj7`, `Ab5m7`).
- **Roman Numeral Analysis**: Chromatic degree analysis under a key signature (e.g. `G7` under `C Major` is analyzed as `V7`, `Eb` is `bIII`).
- **JSON Serialization**: Full serialization/deserialization for core models (`Note`, `Interval`, `Key`).
- **CLI query utility**: Command-line tool to query chords, scales, transposition, and Roman numeral degree analysis.
- **Scores and diagnostics**: Typed score events, rhythm grids, harmony/cadence analysis, voice leading, and stable reports.
- **SMF interoperability**: Checked Standard MIDI File binary encoding and decoding with malformed-input diagnostics.

## Usage & Examples

Here is a literate programming example showing core library usages:

```moonbit
test "Readme examples" {
  // 1. Parsing and transposing notes
  let c4 = @theory.Note::parse("C4").unwrap()
  let m3 = @theory.Interval::parse("M3").unwrap()
  let e4 = c4.transpose(m3)
  inspect(e4.to_string(), content="E4")

  // 2. Generating chords
  let (root, chord_type) = @theory.parse_chord_symbol("Cmaj7").unwrap()
  let notes = @theory.generate_chord(root, chord_type)
  let notes_strs = notes.map(fn(n) { n.to_string() })
  inspect(notes_strs, content="[\"C4\", \"E4\", \"G4\", \"B4\"]")

  // 3. Roman Numeral analysis
  let c_major = @theory.Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let result = c_major.analyze_chord("G7").unwrap()
  inspect(result, content="V7")
}
```

## CLI Commands

You can run the query CLI tool directly:

```bash
# Query chord notes
moon run src/cli -- chord Cmaj7

# Generate scale notes
moon run src/cli -- scale C major

# Transpose a note by an interval
moon run src/cli -- transpose C4 M3

# Roman numeral degree analysis
moon run src/cli -- roman C major G7
moon run src/cli -- report C major I,IV,V,I
moon run src/cli -- midi-roundtrip I,IV,V,I
```

## Development

```bash
moon check --deny-warn
moon test --deny-warn
moon fmt
```
