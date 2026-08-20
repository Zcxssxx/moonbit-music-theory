///|
fn running_status_fixture() -> Bytes {
  Bytes::from_array([
    b'M', b'T', b'h', b'd', 0, 0, 0, 6, 0, 0, 0, 1, 0x01, 0xE0, b'M', b'T', b'r',
    b'k', 0, 0, 0, 11, 0, 0x90, 60, 64, 16, 60, 0, 0, 0xFF, 0x2F, 0,
  ])
}

///|
fn named_empty_track_fixture() -> Bytes {
  Bytes::from_array([
    b'M', b'T', b'h', b'd', 0, 0, 0, 6, 0, 0, 0, 1, 0x01, 0xE0, b'M', b'T', b'r',
    b'k', 0, 0, 0, 9, 0, 0xFF, 0x03, 1, b'A', 0, 0xFF, 0x2F, 0,
  ])
}

///|
test "variable length quantities use canonical MIDI bytes" {
  debug_inspect(
    encode_variable_length(0).map(fn(byte) { byte.to_int() }),
    content="[0]",
  )
  debug_inspect(
    encode_variable_length(127).map(fn(byte) { byte.to_int() }),
    content="[127]",
  )
  debug_inspect(
    encode_variable_length(128).map(fn(byte) { byte.to_int() }),
    content="[129, 0]",
  )
  debug_inspect(
    encode_variable_length(0x0fffffff).map(fn(byte) { byte.to_int() }),
    content="[255, 255, 255, 127]",
  )
}

///|
test "variable length quantities decode boundary values" {
  let v0 = decode_variable_length(b"\x00", 0)
  let v1 = decode_variable_length(b"\x7f", 0)
  let v2 = decode_variable_length(b"\x81\x00", 0)
  let v3 = decode_variable_length(b"\xff\x7f", 0)
  let v4 = decode_variable_length(b"\x81\x80\x00", 0)
  let v5 = decode_variable_length(b"\xff\xff\xff\x7f", 0)
  debug_inspect(v0, content="(0, 1)")
  debug_inspect(v1, content="(127, 1)")
  debug_inspect(v2, content="(128, 2)")
  debug_inspect(v3, content="(16383, 2)")
  debug_inspect(v4, content="(16384, 3)")
  debug_inspect(v5, content="(268435455, 4)")
}

///|
test "variable length quantities reject invalid values" {
  try encode_variable_length(-1) catch {
    err =>
      inspect(
        err.to_string(),
        content="MIDI variable-length quantity must be between 0 and 268435455",
      )
  } noraise {
    _ => fail("expected negative VLQ error")
  }

  try encode_variable_length(0x10000000) catch {
    err =>
      inspect(
        err.to_string(),
        content="MIDI variable-length quantity must be between 0 and 268435455",
      )
  } noraise {
    _ => fail("expected out-of-range VLQ error")
  }

  try decode_variable_length(b"", 0) catch {
    err =>
      inspect(
        err.to_string(),
        content="unexpected end of MIDI data at offset 0 while reading variable-length quantity",
      )
  } noraise {
    _ => fail("expected empty VLQ error")
  }

  try decode_variable_length(b"\x80", 0) catch {
    err =>
      inspect(
        err.to_string(),
        content="unexpected end of MIDI data at offset 1 while reading variable-length quantity",
      )
  } noraise {
    _ => fail("expected unterminated VLQ error")
  }

  try decode_variable_length(b"\x81\x80\x80\x80\x00", 0) catch {
    err =>
      inspect(
        err.to_string(),
        content="MIDI variable-length quantity exceeds four bytes at offset 0",
      )
  } noraise {
    _ => fail("expected long VLQ error")
  }

  try decode_variable_length(b"\x80\x00", 0) catch {
    err =>
      inspect(
        err.to_string(),
        content="non-canonical MIDI variable-length quantity at offset 0",
      )
  } noraise {
    _ => fail("expected non-canonical zero VLQ error")
  }

  try decode_variable_length(b"\x80\x81\x00", 0) catch {
    err =>
      inspect(
        err.to_string(),
        content="non-canonical MIDI variable-length quantity at offset 0",
      )
  } noraise {
    _ => fail("expected non-canonical leading-zero VLQ error")
  }
}

///|
test "MIDI decoder rejects truncated track chunks" {
  try MidiFile::from_smf([b'M', b'T', b'h', b'd', 0, 0, 0, 6]) catch {
    err =>
      inspect(err.to_string(), content="unexpected end of MIDI data at header")
  } noraise {
    _ => fail("expected truncated MIDI error")
  }
}

///|
test "MIDI decoder validates header format and division" {
  try
    MidiFile::from_smf([
      b'M', b'T', b'h', b'd', 0, 0, 0, 6, 0, 2, 0, 1, 0x01, 0xE0,
    ])
  catch {
    err =>
      inspect(err.to_string(), content="unsupported MIDI format 2 at header")
  } noraise {
    _ => fail("expected format error")
  }

  try
    MidiFile::from_smf([b'M', b'T', b'h', b'd', 0, 0, 0, 6, 0, 0, 0, 1, 0, 0])
  catch {
    err =>
      inspect(
        err.to_string(),
        content="MIDI division must be positive at header",
      )
  } noraise {
    _ => fail("expected division error")
  }

  try
    MidiFile::from_smf([
      b'M', b'T', b'h', b'd', 0, 0, 0, 6, 0, 0, 0, 2, 0x01, 0xE0, b'M', b'T', b'r',
      b'k', 0, 0, 0, 4, 0, 0xFF, 0x2F, 0, b'M', b'T', b'r', b'k', 0, 0, 0, 4, 0,
      0xFF, 0x2F, 0,
    ])
  catch {
    err =>
      inspect(
        err.to_string(),
        content="MIDI format 0 must declare exactly one track at header",
      )
  } noraise {
    _ => fail("expected format-0 track-count error")
  }
}

///|
test "MIDI decoder handles running status and note-on velocity zero" {
  let midi = MidiFile::from_smf(running_status_fixture())
  inspect(midi.ppq, content="480")
  inspect(midi.tracks.length(), content="1")
  inspect(midi.tracks[0].events.length(), content="2")

  let first = midi.tracks[0].events[0]
  inspect(first.delta_time, content="0")
  inspect(first.status, content="144")
  inspect(first.data1, content="60")
  inspect(first.data2, content="64")

  let second = midi.tracks[0].events[1]
  inspect(second.delta_time, content="16")
  inspect(second.status, content="128")
  inspect(second.data1, content="60")
  inspect(second.data2, content="0")
}

///|
test "MIDI decoder reads track name meta events into the track model" {
  let midi = MidiFile::from_smf(named_empty_track_fixture())
  inspect(midi.tracks.length(), content="1")
  inspect(midi.tracks[0].name, content="A")
  inspect(midi.tracks[0].events.length(), content="0")
}

///|
test "MIDI decoder requires an explicit end-of-track event" {
  try
    MidiFile::from_smf([
      b'M', b'T', b'h', b'd', 0, 0, 0, 6, 0, 0, 0, 1, 0x01, 0xE0, b'M', b'T', b'r',
      b'k', 0, 0, 0, 4, 0, 0x90, 60, 64,
    ])
  catch {
    err =>
      inspect(
        err.to_string(),
        content="missing end-of-track meta event in track 0",
      )
  } noraise {
    _ => fail("expected missing end-of-track error")
  }
}

///|
test "MIDI decoder rejects uninterpretable trailing bytes after end-of-track" {
  try
    MidiFile::from_smf([
      b'M', b'T', b'h', b'd', 0, 0, 0, 6, 0, 0, 0, 1, 0x01, 0xE0, b'M', b'T', b'r',
      b'k', 0, 0, 0, 8, 0, 0xFF, 0x2F, 0, 0, 0x90, 60, 64,
    ])
  catch {
    err =>
      inspect(
        err.to_string(),
        content="trailing MIDI bytes after end-of-track in track 0 at offset 26",
      )
  } noraise {
    _ => fail("expected trailing-byte error")
  }
}

///|
test "MIDI binary round trips preserve empty tracks and names" {
  let midi = MidiFile::new(480)
  let track = midi.add_track("Lead")
  ignore(track)

  let encoded = midi.to_smf()
  let decoded = MidiFile::from_smf(encoded)
  inspect(decoded.ppq, content="480")
  inspect(decoded.tracks.length(), content="1")
  inspect(decoded.tracks[0].name, content="Lead")
  inspect(decoded.tracks[0].events.length(), content="0")
}

///|
test "MIDI encoder rejects files with zero tracks" {
  try MidiFile::new(480).to_smf() catch {
    err =>
      inspect(
        err.to_string(),
        content="MIDI file must contain at least one track",
      )
  } noraise {
    _ => fail("expected zero-track MIDI error")
  }
}

///|
test "MIDI binary round trips supported channel events semantically" {
  let midi = MidiFile::new(960)
  let track = midi.add_track("Progression")
  let c4 = Note::parse("C4").unwrap()
  let e4 = Note::parse("E4").unwrap()
  track.add_note_on(0, c4, 90)
  track.add_note_on(120, e4, 0)
  track.add_note_off(240, c4)

  let encoded = midi.to_smf()
  let decoded = MidiFile::from_smf(encoded)
  inspect(decoded.ppq, content="960")
  inspect(decoded.tracks.length(), content="1")
  inspect(decoded.tracks[0].name, content="Progression")
  inspect(decoded.tracks[0].events.length(), content="3")
  debug_inspect(
    decoded.tracks[0].events,
    content=(
      #|[
      #|  { delta_time: 0, status: 144, data1: 60, data2: 90 },
      #|  { delta_time: 120, status: 128, data1: 64, data2: 0 },
      #|  { delta_time: 240, status: 128, data1: 60, data2: 0 },
      #|]
    ),
  )
}

///|
test "MIDI encoder rejects nonzero data2 for one-data-byte channel events" {
  let midi = MidiFile::new(480)
  let track = midi.add_track("Programs")
  track.events.push({ delta_time: 0, status: 0xC0, data1: 5, data2: 77 })

  try midi.to_smf() catch {
    err =>
      inspect(
        err.to_string(),
        content="MIDI status 0xc0 cannot encode nonzero data2",
      )
  } noraise {
    _ => fail("expected program-change data2 error")
  }
}

///|
test "MIDI encoder round trips one-data-byte channel events with data2 zero" {
  let midi = MidiFile::new(480)
  let track = midi.add_track("Programs")
  track.events.push({ delta_time: 0, status: 0xC0, data1: 5, data2: 0 })
  track.events.push({ delta_time: 12, status: 0xD0, data1: 64, data2: 0 })

  let decoded = MidiFile::from_smf(midi.to_smf())
  debug_inspect(
    decoded.tracks[0].events,
    content=(
      #|[
      #|  { delta_time: 0, status: 192, data1: 5, data2: 0 },
      #|  { delta_time: 12, status: 208, data1: 64, data2: 0 },
      #|]
    ),
  )
}
