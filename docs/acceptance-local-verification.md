# Local Acceptance Verification

This repository is prepared locally for the August MoonBit Hackathon acceptance workflow. No remote push or package publication is performed in this workspace.

## Verified locally

- `moon test src/theory --deny-warn`: 103/103 passed.
- `moon check --target all --deny-warn`: passed.
- `moon check src/cli --deny-warn`: passed.
- `moon check bench --deny-warn`: passed.
- CLI report, report JSON, MIDI round-trip, and deterministic generation commands were executed successfully.
- Boundary/integration coverage includes empty scores, unsupported meters, invalid voice ranges, malformed MIDI, extreme MIDI notes, report determinism, and SMF semantic round trips.

## Source scale

Measured by `scripts/source-stats.ps1` on the working tree:

| Scope | Files | Lines |
| --- | ---: | ---: |
| Production MoonBit (`*.mbt`, excluding test/whitebox files) | 28 | 6,113 |
| Test and whitebox MoonBit | 31 | 2,271 |
| Total MoonBit under `src/` | 59 | 8,384 |

These counts are measured, not padded or inferred. The total MoonBit source footprint exceeds 8,000 lines; the production-only count is reported separately for transparency.

## Native benchmark status

`bench/main.mbt` performs report generation, constrained voice leading, and SMF round trips with a deterministic checksum and no wall-clock dependency. The local native runtime currently fails before executing the fixture because `C:\Users\gunter\.moon\lib\runtime\env.c` calls undeclared `rand_s`. `scripts/benchmark.ps1` records the warm-up and five failed attempts as `timing_samples: none`; it does not fabricate benchmark numbers.
