///|
pub fn ScoreReport::to_json(self : ScoreReport) -> Json {
  Json::Json(self)
}

///|
pub impl ToJson for PitchHistogram with fn to_json(self : PitchHistogram) -> Json {
  Json::array(self.counts.map(fn(count) { Json::number(count.to_double()) }))
}

///|
pub impl @json.FromJson for PitchHistogram with fn from_json(json, path) {
  let counts : Array[Int] = @json.from_json(json, path~)
  if counts.length() != 12 {
    raise @json.JsonDecodeError(
      (path, "PitchHistogram::from_json: expected 12 pitch-class counts"),
    )
  }
  { counts, }
}

///|
pub impl ToJson for RhythmSummary with fn to_json(self : RhythmSummary) -> Json {
  make_report_json_object([
    ("meter_supported", Json::boolean(self.meter_supported)),
    ("beat_ticks", Json::number(self.beat_ticks.to_double())),
    ("beat_count", Json::number(self.beat_count.to_double())),
    (
      "average_duration_ticks",
      Json::number(self.average_duration_ticks.to_double()),
    ),
    (
      "density_per_beat_milli",
      Json::number(self.density_per_beat_milli.to_double()),
    ),
    ("syncopation", Json::number(self.syncopation.to_double())),
    ("on_beat_attacks", Json::number(self.on_beat_attacks.to_double())),
    ("off_beat_attacks", Json::number(self.off_beat_attacks.to_double())),
  ])
}

///|
pub impl @json.FromJson for RhythmSummary with fn from_json(json, path) {
  let object = expect_report_object(json, path, "RhythmSummary::from_json")
  {
    meter_supported: decode_report_bool_field(
      object, "meter_supported", path, "RhythmSummary::from_json",
    ),
    beat_ticks: decode_report_int_field(
      object, "beat_ticks", path, "RhythmSummary::from_json",
    ),
    beat_count: decode_report_int_field(
      object, "beat_count", path, "RhythmSummary::from_json",
    ),
    average_duration_ticks: decode_report_int_field(
      object, "average_duration_ticks", path, "RhythmSummary::from_json",
    ),
    density_per_beat_milli: decode_report_int_field(
      object, "density_per_beat_milli", path, "RhythmSummary::from_json",
    ),
    syncopation: decode_report_int_field(
      object, "syncopation", path, "RhythmSummary::from_json",
    ),
    on_beat_attacks: decode_report_int_field(
      object, "on_beat_attacks", path, "RhythmSummary::from_json",
    ),
    off_beat_attacks: decode_report_int_field(
      object, "off_beat_attacks", path, "RhythmSummary::from_json",
    ),
  }
}

///|
pub impl ToJson for HarmonySummary with fn to_json(self : HarmonySummary) -> Json {
  make_report_json_object([
    ("symbol_count", Json::number(self.symbol_count.to_double())),
    ("cadence", Json::string(self.cadence.to_string())),
    ("tonic_count", Json::number(self.tonic_count.to_double())),
    ("predominant_count", Json::number(self.predominant_count.to_double())),
    ("dominant_count", Json::number(self.dominant_count.to_double())),
    ("ambiguous_count", Json::number(self.ambiguous_count.to_double())),
    ("finding_count", Json::number(self.finding_count.to_double())),
  ])
}

///|
pub impl @json.FromJson for HarmonySummary with fn from_json(json, path) {
  let object = expect_report_object(json, path, "HarmonySummary::from_json")
  {
    symbol_count: decode_report_int_field(
      object, "symbol_count", path, "HarmonySummary::from_json",
    ),
    cadence: decode_cadence_kind(
      expect_report_key(object, "cadence", path, "HarmonySummary::from_json"),
      path.add_key("cadence"),
    ),
    tonic_count: decode_report_int_field(
      object, "tonic_count", path, "HarmonySummary::from_json",
    ),
    predominant_count: decode_report_int_field(
      object, "predominant_count", path, "HarmonySummary::from_json",
    ),
    dominant_count: decode_report_int_field(
      object, "dominant_count", path, "HarmonySummary::from_json",
    ),
    ambiguous_count: decode_report_int_field(
      object, "ambiguous_count", path, "HarmonySummary::from_json",
    ),
    finding_count: decode_report_int_field(
      object, "finding_count", path, "HarmonySummary::from_json",
    ),
  }
}

///|
pub impl ToJson for ScoreReport with fn to_json(self : ScoreReport) -> Json {
  make_report_json_object([
    ("duration_ticks", Json::number(self.duration_ticks.to_double())),
    ("track_count", Json::number(self.track_count.to_double())),
    ("note_event_count", Json::number(self.note_event_count.to_double())),
    ("chord_event_count", Json::number(self.chord_event_count.to_double())),
    ("pitch_histogram", self.pitch_histogram.to_json()),
    ("register_min", note_option_to_json(self.register_min)),
    ("register_max", note_option_to_json(self.register_max)),
    (
      "melodic_intervals",
      Json::array(
        self.melodic_intervals.map(fn(interval) {
          Json::number(interval.to_double())
        }),
      ),
    ),
    ("rhythm_summary", self.rhythm_summary.to_json()),
    ("harmony_summary", self.harmony_summary.to_json()),
    (
      "voice_leading_warning_count",
      Json::number(self.voice_leading_warning_count.to_double()),
    ),
  ])
}

///|
pub impl @json.FromJson for ScoreReport with fn from_json(json, path) {
  let object = expect_report_object(json, path, "ScoreReport::from_json")
  {
    duration_ticks: decode_report_int_field(
      object, "duration_ticks", path, "ScoreReport::from_json",
    ),
    track_count: decode_report_int_field(
      object, "track_count", path, "ScoreReport::from_json",
    ),
    note_event_count: decode_report_int_field(
      object, "note_event_count", path, "ScoreReport::from_json",
    ),
    chord_event_count: decode_report_int_field(
      object, "chord_event_count", path, "ScoreReport::from_json",
    ),
    pitch_histogram: @json.from_json(
      expect_report_key(
        object, "pitch_histogram", path, "ScoreReport::from_json",
      ),
      path=path.add_key("pitch_histogram"),
    ),
    register_min: decode_note_option(
      expect_report_key(object, "register_min", path, "ScoreReport::from_json"),
      path.add_key("register_min"),
    ),
    register_max: decode_note_option(
      expect_report_key(object, "register_max", path, "ScoreReport::from_json"),
      path.add_key("register_max"),
    ),
    melodic_intervals: @json.from_json(
      expect_report_key(
        object, "melodic_intervals", path, "ScoreReport::from_json",
      ),
      path=path.add_key("melodic_intervals"),
    ),
    rhythm_summary: @json.from_json(
      expect_report_key(
        object, "rhythm_summary", path, "ScoreReport::from_json",
      ),
      path=path.add_key("rhythm_summary"),
    ),
    harmony_summary: @json.from_json(
      expect_report_key(
        object, "harmony_summary", path, "ScoreReport::from_json",
      ),
      path=path.add_key("harmony_summary"),
    ),
    voice_leading_warning_count: decode_report_int_field(
      object, "voice_leading_warning_count", path, "ScoreReport::from_json",
    ),
  }
}

///|
fn note_option_to_json(note : Note?) -> Json {
  match note {
    Some(value) => value.to_json()
    None => Json::null()
  }
}

///|
fn decode_note_option(
  json : Json,
  path : @json.JsonPath,
) -> Note? raise @json.JsonDecodeError {
  match json {
    Null => None
    _ => Some(@json.from_json(json, path~))
  }
}

///|
fn decode_cadence_kind(
  json : Json,
  path : @json.JsonPath,
) -> CadenceKind raise @json.JsonDecodeError {
  let raw : String = @json.from_json(json, path~)
  match raw {
    "Authentic" => Authentic
    "Plagal" => Plagal
    "Deceptive" => Deceptive
    "Half" => Half
    "Undetermined" => Undetermined
    _ =>
      raise @json.JsonDecodeError(
        (path, "HarmonySummary::from_json: unknown cadence " + raw),
      )
  }
}

///|
fn make_report_json_object(pairs : Array[(String, Json)]) -> Json {
  let object : Map[String, Json] = Map([], capacity=pairs.length())
  for pair in pairs {
    object[pair.0] = pair.1
  }
  Json::object(object)
}

///|
fn expect_report_object(
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
fn expect_report_key(
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
fn decode_report_int_field(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Int raise @json.JsonDecodeError {
  @json.from_json(
    expect_report_key(object, key, path, context),
    path=path.add_key(key),
  )
}

///|
fn decode_report_bool_field(
  object : Map[String, Json],
  key : String,
  path : @json.JsonPath,
  context : String,
) -> Bool raise @json.JsonDecodeError {
  @json.from_json(
    expect_report_key(object, key, path, context),
    path=path.add_key(key),
  )
}
