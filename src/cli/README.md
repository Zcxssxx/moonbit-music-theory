# Music Theory CLI

The CLI exposes small, deterministic examples over the public theory APIs.

```text
moon run src/cli -- chord Cmaj7
moon run src/cli -- report C major I,IV,V,I
moon run src/cli -- report-json C major I,IV,V,I
moon run src/cli -- midi-roundtrip I,IV,V,I
moon run src/cli -- generate C major 4 7
```

`report` prints stable text metrics including duration, pitch-class histogram,
rhythm, and harmony. `report-json` emits the same aggregate in JSON.
`midi-roundtrip` exercises the SMF binary encoder and decoder and reports the
decoded track/event counts. `generate` uses a deterministic seeded rotation
of a compact roman-numeral fixture before invoking the progression API.

The acceptance fixture is stored in `fixtures/demo-score.txt`.
