///|
pub(all) struct NoteEvent {
  note : Note
  start_tick : Int
  duration_ticks : Int
  velocity : Int
  channel : Int
} derive(Eq, Debug)

///|
pub(all) struct ChordEvent {
  root : Note
  chord_type : ChordType
  start_tick : Int
  duration_ticks : Int
  velocity : Int
  channel : Int
} derive(Eq, Debug)

///|
pub(all) struct TempoPoint {
  start_tick : Int
  bpm : Double
} derive(Eq, Debug)

///|
pub(all) struct ScoreTrack {
  name : String
  events : Array[NoteEvent]
  chord_events : Array[ChordEvent]
} derive(Eq, Debug)

///|
pub(all) struct Score {
  ppq : Int
  tracks : Array[ScoreTrack]
  tempo_map : Array[TempoPoint]
  time_signature : TimeSignature
} derive(Eq, Debug)

///|
pub fn NoteEvent::new(
  note : Note,
  start_tick : Int,
  duration_ticks : Int,
  velocity : Int,
  channel : Int,
) -> NoteEvent raise Failure {
  validate_start_tick(start_tick)
  validate_duration_ticks(duration_ticks)
  validate_velocity(velocity)
  validate_channel(channel)
  { note, start_tick, duration_ticks, velocity, channel }
}

///|
pub fn ChordEvent::new(
  root : Note,
  chord_type : ChordType,
  start_tick : Int,
  duration_ticks : Int,
  velocity : Int,
  channel : Int,
) -> ChordEvent raise Failure {
  validate_start_tick(start_tick)
  validate_duration_ticks(duration_ticks)
  validate_velocity(velocity)
  validate_channel(channel)
  { root, chord_type, start_tick, duration_ticks, velocity, channel }
}

///|
pub fn TempoPoint::new(
  start_tick : Int,
  bpm : Double,
) -> TempoPoint raise Failure {
  validate_start_tick(start_tick)
  if bpm <= 0.0 {
    fail("bpm must be positive")
  }
  { start_tick, bpm }
}

///|
pub fn Score::new(
  ppq : Int,
  time_signature? : TimeSignature = TimeSignature::new(4, 4),
) -> Score raise Failure {
  if ppq <= 0 {
    fail("ppq must be positive")
  }
  { ppq, tracks: [], tempo_map: [], time_signature }
}

///|
pub fn Score::add_track(self : Score, name : String) -> ScoreTrack {
  let track = { name, events: [], chord_events: [] }
  self.tracks.push(track)
  track
}

///|
pub fn Score::add_tempo_point(self : Score, tempo_point : TempoPoint) -> Unit {
  insert_sorted_tempo_point(self.tempo_map, tempo_point)
}

///|
pub fn ScoreTrack::add_note(self : ScoreTrack, event : NoteEvent) -> Unit {
  insert_sorted_note_event(self.events, event)
}

///|
pub fn ScoreTrack::add_chord(self : ScoreTrack, event : ChordEvent) -> Unit {
  insert_sorted_chord_event(self.chord_events, event)
}

///|
pub fn Score::duration_ticks(self : Score) -> Int {
  let mut duration = 0
  for track in self.tracks {
    for event in track.events {
      let end_tick = event.start_tick + event.duration_ticks
      if end_tick > duration {
        duration = end_tick
      }
    }
    for event in track.chord_events {
      let end_tick = event.start_tick + event.duration_ticks
      if end_tick > duration {
        duration = end_tick
      }
    }
  }
  duration
}

///|
pub fn Score::transpose(self : Score, interval : Interval) -> Score {
  let tracks = self.tracks.map(fn(track) {
    {
      name: track.name,
      events: track.events.map(fn(event) {
        {
          note: event.note.transpose(interval),
          start_tick: event.start_tick,
          duration_ticks: event.duration_ticks,
          velocity: event.velocity,
          channel: event.channel,
        }
      }),
      chord_events: track.chord_events.map(fn(event) {
        {
          root: event.root.transpose(interval),
          chord_type: event.chord_type,
          start_tick: event.start_tick,
          duration_ticks: event.duration_ticks,
          velocity: event.velocity,
          channel: event.channel,
        }
      }),
    }
  })
  {
    ppq: self.ppq,
    tracks,
    tempo_map: copy_tempo_map(self.tempo_map),
    time_signature: self.time_signature,
  }
}

///|
pub fn Score::stretch(self : Score, factor : Double) -> Score raise Failure {
  if factor <= 0.0 {
    fail("stretch factor must be greater than zero")
  }
  let tracks = self.tracks.map(track => {
    name: track.name,
    events: track.events.map(event => stretch_note_event(event, factor)),
    chord_events: track.chord_events.map(event => {
      stretch_chord_event(event, factor)
    }),
  })
  {
    ppq: self.ppq,
    tracks,
    tempo_map: self.tempo_map.map(fn(point) {
      { start_tick: scale_ticks(point.start_tick, factor), bpm: point.bpm }
    }),
    time_signature: self.time_signature,
  }
}

///|
fn validate_start_tick(start_tick : Int) -> Unit raise Failure {
  if start_tick < 0 {
    fail("start tick must be non-negative")
  }
}

///|
fn validate_duration_ticks(duration_ticks : Int) -> Unit raise Failure {
  if duration_ticks <= 0 {
    fail("duration ticks must be positive")
  }
}

///|
fn validate_velocity(velocity : Int) -> Unit raise Failure {
  if velocity < 0 || velocity > 127 {
    fail("velocity must be between 0 and 127")
  }
}

///|
fn validate_channel(channel : Int) -> Unit raise Failure {
  if channel < 0 || channel > 15 {
    fail("channel must be between 0 and 15")
  }
}

///|
fn scale_ticks(ticks : Int, factor : Double) -> Int {
  (ticks.to_double() * factor + 0.5).to_int()
}

///|
fn stretch_note_event(
  event : NoteEvent,
  factor : Double,
) -> NoteEvent raise Failure {
  let start_tick = scale_ticks(event.start_tick, factor)
  let duration_ticks = scale_ticks(event.duration_ticks, factor)
  if duration_ticks <= 0 {
    fail(
      "stretch would collapse note event duration to zero: " +
      event.note.to_string() +
      " at tick " +
      event.start_tick.to_string() +
      " duration " +
      event.duration_ticks.to_string() +
      " factor " +
      factor.to_string(),
    )
  }
  NoteEvent::new(
    event.note,
    start_tick,
    duration_ticks,
    event.velocity,
    event.channel,
  )
}

///|
fn stretch_chord_event(
  event : ChordEvent,
  factor : Double,
) -> ChordEvent raise Failure {
  let start_tick = scale_ticks(event.start_tick, factor)
  let duration_ticks = scale_ticks(event.duration_ticks, factor)
  if duration_ticks <= 0 {
    fail(
      "stretch would collapse chord event duration to zero: " +
      event.root.to_string() +
      " " +
      event.chord_type.to_string() +
      " at tick " +
      event.start_tick.to_string() +
      " duration " +
      event.duration_ticks.to_string() +
      " factor " +
      factor.to_string(),
    )
  }
  ChordEvent::new(
    event.root,
    event.chord_type,
    start_tick,
    duration_ticks,
    event.velocity,
    event.channel,
  )
}

///|
fn insert_sorted_note_event(
  events : Array[NoteEvent],
  event : NoteEvent,
) -> Unit {
  let mut index = events.length()
  for i in 0..<events.length() {
    if event.start_tick < events[i].start_tick {
      index = i
      break
    }
  }
  events.insert(index, event)
}

///|
fn insert_sorted_chord_event(
  events : Array[ChordEvent],
  event : ChordEvent,
) -> Unit {
  let mut index = events.length()
  for i in 0..<events.length() {
    if event.start_tick < events[i].start_tick {
      index = i
      break
    }
  }
  events.insert(index, event)
}

///|
fn insert_sorted_tempo_point(
  tempo_map : Array[TempoPoint],
  tempo_point : TempoPoint,
) -> Unit {
  let mut index = tempo_map.length()
  for i in 0..<tempo_map.length() {
    if tempo_point.start_tick < tempo_map[i].start_tick {
      index = i
      break
    }
  }
  tempo_map.insert(index, tempo_point)
}

///|
fn copy_tempo_map(tempo_map : Array[TempoPoint]) -> Array[TempoPoint] {
  tempo_map.map(fn(point) { { start_tick: point.start_tick, bpm: point.bpm } })
}
