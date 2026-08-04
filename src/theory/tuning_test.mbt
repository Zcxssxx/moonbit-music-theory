///|
test "tuning systems calculations" {
  let c4 = Note::parse("C4").unwrap()
  let e4 = Note::parse("E4").unwrap()
  let g4 = Note::parse("G4").unwrap()

  // 12-TET check
  let c4_freq_eq = c4.frequency_tuned(TuningSystem::EqualTemperament, 440.0)
  inspect(c4_freq_eq, content="261.6255653005986")

  // Pythagorean check
  // E4 in Pythagorean is C4 * 81/64
  let c4_freq_py = c4.frequency_tuned(TuningSystem::Pythagorean, 440.0)
  let e4_freq_py = e4.frequency_tuned(TuningSystem::Pythagorean, 440.0)
  let ratio_py = e4_freq_py / c4_freq_py
  inspect(ratio_py, content="1.265625") // 81/64 = 1.265625

  // Just Intonation check
  // E4 in Just is C4 * 5/4
  let c4_freq_ji = c4.frequency_tuned(TuningSystem::JustIntonation, 440.0)
  let e4_freq_ji = e4.frequency_tuned(TuningSystem::JustIntonation, 440.0)
  let ratio_ji = e4_freq_ji / c4_freq_ji
  inspect(ratio_ji, content="1.25") // 5/4 = 1.25

  // Meantone check
  let c4_freq_mt = c4.frequency_tuned(TuningSystem::Meantone, 440.0)
  let e4_freq_mt = e4.frequency_tuned(TuningSystem::Meantone, 440.0)
  let ratio_mt = e4_freq_mt / c4_freq_mt
  inspect(ratio_mt, content="1.25") // pure major third E4/C4 = 1.25

  let g4_freq_mt = g4.frequency_tuned(TuningSystem::Meantone, 440.0)
  let ratio_g4_mt = g4_freq_mt / c4_freq_mt
  inspect(ratio_g4_mt, content="1.4953487812212205") // 5^(1/4) = 1.49534878...
}
