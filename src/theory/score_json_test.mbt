///|
test "score json roundtrip preserves notes and tempo" {
  let score = Score::new(960, time_signature=TimeSignature::new(3, 4))
  score.add_tempo_point(TempoPoint::new(0, 120.0))
  let track = score.add_track("lead")
  track.add_note(NoteEvent::new(Note::parse("C4").unwrap(), 0, 960, 100, 0))
  track.add_chord(
    ChordEvent::new(
      Note::parse("F4").unwrap(),
      ChordType::MajorTriad,
      960,
      480,
      88,
      1,
    ),
  )

  let encoded = score.to_json()
  let decoded : Result[Score, String] = Ok(@json.from_json(encoded)) catch {
    err => Err(err.to_string())
  }
  let printed = match decoded {
    Ok(value) =>
      value.tracks[0].events[0].note.to_string() +
      "|" +
      value.tempo_map[0].bpm.to_string()
    Err(err) => "Err(" + err + ")"
  }
  inspect(printed, content="C4|120")
}

///|
test "score json preserves decode context" {
  let invalid = Json::object({
    "ppq": Json::number(480.0),
    "tracks": Json::array([]),
    "tempo_map": Json::array([
      Json::object({ "start_tick": Json::number(0.0), "bpm": Json::number(0.0) }),
    ]),
    "time_signature": Json::object({
      "beats": Json::number(4.0),
      "beat_value": Json::number(4.0),
    }),
  })

  let decoded : Result[Score, String] = Ok(@json.from_json(invalid)) catch {
    err => Err(err.to_string())
  }
  let printed = match decoded {
    Ok(_) => "Ok"
    Err(err) => err
  }
  inspect(printed.contains("TempoPoint::from_json"), content="true")
}

///|
test "score json decode reuses sorted insertion paths" {
  let encoded = Json::object({
    "ppq": Json::number(480.0),
    "tracks": Json::array([
      Json::object({
        "name": Json::string("lead"),
        "events": Json::array([
          Json::object({
            "note": Json::string("G4"),
            "start_tick": Json::number(480.0),
            "duration_ticks": Json::number(120.0),
            "velocity": Json::number(80.0),
            "channel": Json::number(0.0),
          }),
          Json::object({
            "note": Json::string("C4"),
            "start_tick": Json::number(0.0),
            "duration_ticks": Json::number(240.0),
            "velocity": Json::number(70.0),
            "channel": Json::number(0.0),
          }),
        ]),
        "chord_events": Json::array([
          Json::object({
            "root": Json::string("G4"),
            "chord_type": Json::string("major"),
            "start_tick": Json::number(960.0),
            "duration_ticks": Json::number(240.0),
            "velocity": Json::number(80.0),
            "channel": Json::number(1.0),
          }),
          Json::object({
            "root": Json::string("C4"),
            "chord_type": Json::string("major"),
            "start_tick": Json::number(240.0),
            "duration_ticks": Json::number(240.0),
            "velocity": Json::number(80.0),
            "channel": Json::number(1.0),
          }),
        ]),
      }),
    ]),
    "tempo_map": Json::array([
      Json::object({
        "start_tick": Json::number(960.0),
        "bpm": Json::number(90.0),
      }),
      Json::object({
        "start_tick": Json::number(0.0),
        "bpm": Json::number(120.0),
      }),
    ]),
    "time_signature": Json::object({
      "beats": Json::number(4.0),
      "beat_value": Json::number(4.0),
    }),
  })

  let decoded : Score = @json.from_json(encoded)
  inspect(decoded.tracks[0].events[0].start_tick, content="0")
  inspect(decoded.tracks[0].events[1].start_tick, content="480")
  inspect(decoded.tracks[0].chord_events[0].start_tick, content="240")
  inspect(decoded.tracks[0].chord_events[1].start_tick, content="960")
  inspect(decoded.tempo_map[0].start_tick, content="0")
  inspect(decoded.tempo_map[1].start_tick, content="960")
}
