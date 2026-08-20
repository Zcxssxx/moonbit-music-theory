///|
pub fn Score::to_json(self : Score) -> Json {
  Json::Json(self)
}

///|
pub fn Score::from_json(json : Json) -> Score raise @json.JsonDecodeError {
  @json.from_json(json)
}

///|
pub impl ToJson for NoteEvent with fn to_json(self : NoteEvent) -> Json {
  make_score_json_object([
    ("note", ToJson::to_json(self.note)),
    ("start_tick", Json::number(self.start_tick.to_double())),
    ("duration_ticks", Json::number(self.duration_ticks.to_double())),
    ("velocity", Json::number(self.velocity.to_double())),
    ("channel", Json::number(self.channel.to_double())),
  ])
}

///|
pub impl @json.FromJson for NoteEvent with fn from_json(json, path) {
  let object = expect_score_object(json, path, "NoteEvent::from_json")
  let note : Note = @json.from_json(
    expect_score_key(object, "note", path, "NoteEvent::from_json"),
    path=path.add_key("note"),
  )
  let start_tick = decode_score_int_field(
    object, "start_tick", path, "NoteEvent::from_json",
  )
  let duration_ticks = decode_score_int_field(
    object, "duration_ticks", path, "NoteEvent::from_json",
  )
  let velocity = decode_score_int_field(
    object, "velocity", path, "NoteEvent::from_json",
  )
  let channel = decode_score_int_field(
    object, "channel", path, "NoteEvent::from_json",
  )
  NoteEvent::new(note, start_tick, duration_ticks, velocity, channel) catch {
    err =>
      raise @json.JsonDecodeError(
        (path, "NoteEvent::from_json: " + err.to_string()),
      )
  }
}

///|
pub impl ToJson for ChordEvent with fn to_json(self : ChordEvent) -> Json {
  make_score_json_object([
    ("root", ToJson::to_json(self.root)),
    ("chord_type", Json::string(self.chord_type.to_string())),
    ("start_tick", Json::number(self.start_tick.to_double())),
    ("duration_ticks", Json::number(self.duration_ticks.to_double())),
    ("velocity", Json::number(self.velocity.to_double())),
    ("channel", Json::number(self.channel.to_double())),
  ])
}

///|
pub impl @json.FromJson for ChordEvent with fn from_json(json, path) {
  let object = expect_score_object(json, path, "ChordEvent::from_json")
  let root : Note = @json.from_json(
    expect_score_key(object, "root", path, "ChordEvent::from_json"),
    path=path.add_key("root"),
  )
  let chord_type = decode_chord_type(
    expect_score_key(object, "chord_type", path, "ChordEvent::from_json"),
    path.add_key("chord_type"),
  )
  let start_tick = decode_score_int_field(
    object, "start_tick", path, "ChordEvent::from_json",
  )
  let duration_ticks = decode_score_int_field(
    object, "duration_ticks", path, "ChordEvent::from_json",
  )
  let velocity = decode_score_int_field(
    object, "velocity", path, "ChordEvent::from_json",
  )
  let channel = decode_score_int_field(
    object, "channel", path, "ChordEvent::from_json",
  )
  ChordEvent::new(
    root, chord_type, start_tick, duration_ticks, velocity, channel,
  ) catch {
    err =>
      raise @json.JsonDecodeError(
        (path, "ChordEvent::from_json: " + err.to_string()),
      )
  }
}

///|
pub impl ToJson for TempoPoint with fn to_json(self : TempoPoint) -> Json {
  make_score_json_object([
    ("start_tick", Json::number(self.start_tick.to_double())),
    ("bpm", Json::number(self.bpm)),
  ])
}

///|
pub impl @json.FromJson for TempoPoint with fn from_json(json, path) {
  let object = expect_score_object(json, path, "TempoPoint::from_json")
  let start_tick = decode_score_int_field(
    object, "start_tick", path, "TempoPoint::from_json",
  )
  let bpm : Double = @json.from_json(
    expect_score_key(object, "bpm", path, "TempoPoint::from_json"),
    path=path.add_key("bpm"),
  )
  TempoPoint::new(start_tick, bpm) catch {
    err =>
      raise @json.JsonDecodeError(
        (path, "TempoPoint::from_json: " + err.to_string()),
      )
  }
}

///|
pub impl ToJson for ScoreTrack with fn to_json(self : ScoreTrack) -> Json {
  make_score_json_object([
    ("name", Json::string(self.name)),
    (
      "events",
      Json::array(self.events.map(fn(event) { ToJson::to_json(event) })),
    ),
    (
      "chord_events",
      Json::array(self.chord_events.map(fn(event) { ToJson::to_json(event) })),
    ),
  ])
}

///|
pub impl @json.FromJson for ScoreTrack with fn from_json(json, path) {
  let object = expect_score_object(json, path, "ScoreTrack::from_json")
  let name : String = @json.from_json(
    expect_score_key(object, "name", path, "ScoreTrack::from_json"),
    path=path.add_key("name"),
  )
  let events : Array[NoteEvent] = @json.from_json(
    expect_score_key(object, "events", path, "ScoreTrack::from_json"),
    path=path.add_key("events"),
  )
  let chord_events : Array[ChordEvent] = @json.from_json(
    expect_score_key(object, "chord_events", path, "ScoreTrack::from_json"),
    path=path.add_key("chord_events"),
  )
  let track = { name, events: [], chord_events: [] }
  for event in events {
    track.add_note(event)
  }
  for event in chord_events {
    track.add_chord(event)
  }
  track
}

///|
pub impl ToJson for Score with fn to_json(self : Score) -> Json {
  make_score_json_object([
    ("ppq", Json::number(self.ppq.to_double())),
    (
      "tracks",
      Json::array(self.tracks.map(fn(track) { ToJson::to_json(track) })),
    ),
    (
      "tempo_map",
      Json::array(self.tempo_map.map(fn(point) { ToJson::to_json(point) })),
    ),
    (
      "time_signature",
      make_score_json_object([
        ("beats", Json::number(self.time_signature.beats.to_double())),
        ("beat_value", Json::number(self.time_signature.beat_value.to_double())),
      ]),
    ),
  ])
}

///|
pub impl @json.FromJson for Score with fn from_json(json, path) {
  let object = expect_score_object(json, path, "Score::from_json")
  let ppq = decode_score_int_field(object, "ppq", path, "Score::from_json")
  let tracks : Array[ScoreTrack] = @json.from_json(
    expect_score_key(object, "tracks", path, "Score::from_json"),
    path=path.add_key("tracks"),
  )
  let tempo_map : Array[TempoPoint] = @json.from_json(
    expect_score_key(object, "tempo_map", path, "Score::from_json"),
    path=path.add_key("tempo_map"),
  )
  let time_signature = decode_time_signature(
    expect_score_key(object, "time_signature", path, "Score::from_json"),
    path.add_key("time_signature"),
  )
  let score = Score::new(ppq, time_signature~) catch {
    err =>
      raise @json.JsonDecodeError(
        (path, "Score::from_json: " + err.to_string()),
      )
  }
  for track in tracks {
    score.tracks.push(track)
  }
  for tempo_point in tempo_map {
    score.add_tempo_point(tempo_point)
  }
  score
}

///|
fn make_score_json_object(pairs : Array[(String, Json)]) -> Json {
  let object : Map[String, Json] = Map([], capacity=pairs.length())
  for pair in pairs {
    object[pair.0] = pair.1
  }
  Json::object(object)
}

///|
fn expect_score_object(
  json : Json,
  path : @json.JsonPath,
  context : String,
) -> Map[String, Json] raise @json.JsonDecodeError {
  match json {
    Object(object) => object
    _ => raise @json.JsonDecodeError((path, context + ": expected object"))
  }
}

///|
fn expect_score_key(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Json raise @json.JsonDecodeError {
  match object.get(key) {
    Some(value) => value
    None =>
      raise @json.JsonDecodeError(
        (path.add_key(key), context + ": missing field"),
      )
  }
}

///|
fn decode_score_int_field(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Int raise @json.JsonDecodeError {
  @json.from_json(
    expect_score_key(object, key, path, context),
    path=path.add_key(key),
  )
}

///|
fn decode_time_signature(
  json : Json,
  path : @json.JsonPath,
) -> TimeSignature raise @json.JsonDecodeError {
  let object = expect_score_object(json, path, "TimeSignature::from_json")
  let beats = decode_score_int_field(
    object, "beats", path, "TimeSignature::from_json",
  )
  let beat_value = decode_score_int_field(
    object, "beat_value", path, "TimeSignature::from_json",
  )
  TimeSignature::new(beats, beat_value)
}

///|
fn decode_chord_type(
  json : Json,
  path : @json.JsonPath,
) -> ChordType raise @json.JsonDecodeError {
  let raw : String = @json.from_json(json, path~)
  match raw {
    "major" => ChordType::MajorTriad
    "minor" => ChordType::MinorTriad
    "diminished" => ChordType::DiminishedTriad
    "augmented" => ChordType::AugmentedTriad
    "major_seventh" => ChordType::MajorSeventh
    "dominant_seventh" => ChordType::DominantSeventh
    "minor_seventh" => ChordType::MinorSeventh
    "half_diminished_seventh" => ChordType::HalfDiminishedSeventh
    "diminished_seventh" => ChordType::DiminishedSeventh
    "major_ninth" => ChordType::MajorNinth
    "minor_ninth" => ChordType::MinorNinth
    "dominant_ninth" => ChordType::DominantNinth
    "major_eleventh" => ChordType::MajorEleventh
    "minor_eleventh" => ChordType::MinorEleventh
    "dominant_eleventh" => ChordType::DominantEleventh
    "major_thirteenth" => ChordType::MajorThirteenth
    "minor_thirteenth" => ChordType::MinorThirteenth
    "dominant_thirteenth" => ChordType::DominantThirteenth
    "suspended_second" => ChordType::SuspendedSecond
    "suspended_fourth" => ChordType::SuspendedFourth
    "altered_seventh_sharp_nine" => ChordType::AlteredSeventhSharpNine
    "altered_seventh_flat_nine" => ChordType::AlteredSeventhFlatNine
    "altered_seventh_flat_five" => ChordType::AlteredSeventhFlatFive
    _ =>
      raise @json.JsonDecodeError(
        (path, "ChordEvent::from_json: unknown chord type " + raw),
      )
  }
}
