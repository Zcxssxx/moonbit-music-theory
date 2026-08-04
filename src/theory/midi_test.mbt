///|
test "MIDI representation and serialization" {
  let midi = MidiFile::new(960)
  let track = midi.add_track("Progression")

  let c4 = Note::parse("C4").unwrap()
  let e4 = Note::parse("E4").unwrap()
  let g4 = Note::parse("G4").unwrap()

  // Add a C Major triad chord lasting 960 ticks
  track.add_chord(0, [c4, e4, g4], 960, 90)

  inspect(midi.ppq, content="960")
  inspect(midi.tracks.length(), content="1")
  inspect(midi.tracks[0].name, content="Progression")

  // 3 Note Ons + 3 Note Offs = 6 events
  inspect(midi.tracks[0].events.length(), content="6")

  // First event is Note On for C4
  let ev0 = midi.tracks[0].events[0]
  inspect(ev0.status, content="144") // 0x90 = 144
  inspect(ev0.data1, content="60") // C4 MIDI = 60
  inspect(ev0.data2, content="90") // velocity
  inspect(ev0.delta_time, content="0")

  // Serializes to JSON cleanly using stringify()
  let printed = midi.to_json().stringify()
  inspect(printed.contains("\"ppq\":960"), content="true")
  inspect(printed.contains("\"name\":\"Progression\""), content="true")
}
