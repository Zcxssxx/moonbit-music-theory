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
- **Score modeling**: Typed note/chord events, tempo maps, time signatures, deterministic transforms, and JSON interchange.
- **Rhythm and harmony diagnostics**: Beat grids, quantization, syncopation, functional harmony, cadence detection, progression scoring, and constrained voice leading.
- **Standard MIDI files**: Checked SMF encoding/decoding with canonical VLQs, running status, track names, and malformed-input diagnostics.
- **Analysis reports**: Stable text/JSON reports with pitch histograms, register, rhythm, harmony, and counterpoint diagnostics.

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

# Generate a deterministic score report
moon run src/cli -- report C major I,IV,V,I

# Encode/decode a MIDI fixture
moon run src/cli -- midi-roundtrip I,IV,V,I
```

## Development

```bash
moon check --deny-warn
moon test --deny-warn
moon fmt
```

The native benchmark fixture is run with `moon run bench --target native --release -- 1000`.
For measured local samples, use `pwsh -File scripts/benchmark.ps1`; the script records a toolchain failure instead of inventing timings when native compilation is unavailable.

## License

Apache-2.0. See [LICENSE](LICENSE).
