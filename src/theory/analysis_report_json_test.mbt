///|
fn report_demo_score() -> Score raise Failure {
  demo_score()
}

///|
test "score report json uses stable field ordering and exact values" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(report_demo_score(), key)

  json_inspect(report.to_json(), content={
    "duration_ticks": 1920,
    "track_count": 2,
    "note_event_count": 4,
    "chord_event_count": 4,
    "pitch_histogram": [2, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
    "register_min": "C4",
    "register_max": "C5",
    "melodic_intervals": [4, 3, 5],
    "rhythm_summary": {
      "meter_supported": true,
      "beat_ticks": 480,
      "beat_count": 4,
      "average_duration_ticks": 480,
      "density_per_beat_milli": 1000,
      "syncopation": 0,
      "on_beat_attacks": 4,
      "off_beat_attacks": 0,
    },
    "harmony_summary": {
      "symbol_count": 4,
      "cadence": "Authentic",
      "tonic_count": 2,
      "predominant_count": 1,
      "dominant_count": 1,
      "ambiguous_count": 0,
      "finding_count": 0,
    },
    "voice_leading_warning_count": 0,
  })
}

///|
test "score report json roundtrip preserves aggregate values" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(report_demo_score(), key)
  let decoded : ScoreReport = @json.from_json(report.to_json())

  inspect(decoded.duration_ticks, content="1920")
  inspect(
    decoded.pitch_histogram,
    content="[2, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]",
  )
  inspect(decoded.rhythm_summary.meter_supported, content="true")
  inspect(decoded.rhythm_summary.syncopation, content="0")
  inspect(decoded.harmony_summary.cadence.to_string(), content="Authentic")
}

///|
test "score report json keeps empty optional fields explicit" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(Score::new(480), key)

  json_inspect(report.to_json(), content={
    "duration_ticks": 0,
    "track_count": 0,
    "note_event_count": 0,
    "chord_event_count": 0,
    "pitch_histogram": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "register_min": null,
    "register_max": null,
    "melodic_intervals": [],
    "rhythm_summary": {
      "meter_supported": true,
      "beat_ticks": 480,
      "beat_count": 0,
      "average_duration_ticks": 0,
      "density_per_beat_milli": 0,
      "syncopation": 0,
      "on_beat_attacks": 0,
      "off_beat_attacks": 0,
    },
    "harmony_summary": {
      "symbol_count": 0,
      "cadence": "Undetermined",
      "tonic_count": 0,
      "predominant_count": 0,
      "dominant_count": 0,
      "ambiguous_count": 0,
      "finding_count": 0,
    },
    "voice_leading_warning_count": 0,
  })
}

///|
test "score report json zeros unsupported meter rhythm fields explicitly" {
  let key = Key::new(NoteLetter::C, Accidental::Natural, ScaleType::Major)
  let report = analyze_score(unsupported_meter_score(), key)

  json_inspect(report.to_json(), content={
    "duration_ticks": 960,
    "track_count": 1,
    "note_event_count": 2,
    "chord_event_count": 0,
    "pitch_histogram": [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
    "register_min": "C4",
    "register_max": "E4",
    "melodic_intervals": [4],
    "rhythm_summary": {
      "meter_supported": false,
      "beat_ticks": 0,
      "beat_count": 0,
      "average_duration_ticks": 480,
      "density_per_beat_milli": 0,
      "syncopation": 0,
      "on_beat_attacks": 0,
      "off_beat_attacks": 0,
    },
    "harmony_summary": {
      "symbol_count": 0,
      "cadence": "Undetermined",
      "tonic_count": 0,
      "predominant_count": 0,
      "dominant_count": 0,
      "ambiguous_count": 0,
      "finding_count": 0,
    },
    "voice_leading_warning_count": 0,
  })
}
