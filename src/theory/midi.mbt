///|
pub(all) struct MidiEvent {
  delta_time : Int
  status : Int
  data1 : Int
  data2 : Int
} derive(Eq, Debug)

///|
pub(all) struct MidiTrack {
  name : String
  events : Array[MidiEvent]
} derive(Eq, Debug)

///|
pub(all) struct MidiFile {
  ppq : Int
  tracks : Array[MidiTrack]
} derive(Eq, Debug)

///|
pub fn MidiFile::new(ppq : Int) -> MidiFile {
  { ppq, tracks: [] }
}

///|
pub fn MidiFile::add_track(self : MidiFile, name : String) -> MidiTrack {
  let track = { name, events: [] }
  self.tracks.push(track)
  track
}

///|
pub fn MidiTrack::add_note_on(
  self : MidiTrack,
  delta_time : Int,
  note : Note,
  velocity : Int,
) -> Unit {
  let midi_pitch = note.to_midi()
  let status = 0x90 // Note On channel 1
  self.events.push({ delta_time, status, data1: midi_pitch, data2: velocity })
}

///|
pub fn MidiTrack::add_note_off(
  self : MidiTrack,
  delta_time : Int,
  note : Note,
) -> Unit {
  let midi_pitch = note.to_midi()
  let status = 0x80 // Note Off channel 1
  self.events.push({ delta_time, status, data1: midi_pitch, data2: 0 })
}

///|
pub fn MidiTrack::add_chord(
  self : MidiTrack,
  delta_time : Int,
  notes : Array[Note],
  duration_ticks : Int,
  velocity : Int,
) -> Unit {
  if notes.length() == 0 {
    return
  }

  // Note ons
  for i in 0..<notes.length() {
    let dt = if i == 0 { delta_time } else { 0 }
    self.add_note_on(dt, notes[i], velocity)
  }

  // Note offs
  for i in 0..<notes.length() {
    let dt = if i == 0 { duration_ticks } else { 0 }
    self.add_note_off(dt, notes[i])
  }
}

///|
fn make_json_object(pairs : Array[(String, Json)]) -> Json {
  let map : Map[String, Json] = Map([], capacity=pairs.length())
  for pair in pairs {
    map.set(pair.0, pair.1)
  }
  Json::object(map)
}

///|
pub fn MidiEvent::to_json(self : MidiEvent) -> Json {
  let map = [
    ("delta_time", Json::number(self.delta_time.to_double())),
    ("status", Json::number(self.status.to_double())),
    ("data1", Json::number(self.data1.to_double())),
    ("data2", Json::number(self.data2.to_double())),
  ]
  make_json_object(map)
}

///|
pub fn MidiTrack::to_json(self : MidiTrack) -> Json {
  let events_json = self.events.map(fn(e) { e.to_json() })
  let map = [
    ("name", Json::string(self.name)),
    ("events", Json::array(events_json)),
  ]
  make_json_object(map)
}

///|
pub fn MidiFile::to_json(self : MidiFile) -> Json {
  let tracks_json = self.tracks.map(fn(t) { t.to_json() })
  let map = [
    ("ppq", Json::number(self.ppq.to_double())),
    ("tracks", Json::array(tracks_json)),
  ]
  make_json_object(map)
}
