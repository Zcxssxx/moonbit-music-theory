///|
pub(all) suberror MidiBinaryError {
  InvalidMidi(String)
} derive(Eq, Debug, ToJson)

///|
pub fn MidiBinaryError::to_string(self : MidiBinaryError) -> String {
  match self {
    InvalidMidi(message) => message
  }
}

///|
pub fn encode_variable_length(value : Int) -> Array[Byte] raise MidiBinaryError {
  if value < 0 || value > 0x0fffffff {
    raise MidiBinaryError::InvalidMidi(
      "MIDI variable-length quantity must be between 0 and 268435455",
    )
  }

  let parts : Array[Byte] = [value.land(0x7f).to_byte()]
  let mut remaining = value >> 7
  while remaining > 0 {
    parts.insert(0, remaining.land(0x7f).lor(0x80).to_byte())
    remaining = remaining >> 7
  }
  parts
}

///|
pub fn decode_variable_length(
  bytes : Bytes,
  offset : Int,
) -> (Int, Int) raise MidiBinaryError {
  if offset < 0 || offset > bytes.length() {
    raise MidiBinaryError::InvalidMidi(
      "invalid MIDI offset " +
      offset.to_string() +
      " for variable-length quantity",
    )
  }

  let mut value = 0
  let mut cursor = offset
  let mut count = 0
  while true {
    if cursor >= bytes.length() {
      raise MidiBinaryError::InvalidMidi(
        "unexpected end of MIDI data at offset " +
        cursor.to_string() +
        " while reading variable-length quantity",
      )
    }
    if count == 4 {
      raise MidiBinaryError::InvalidMidi(
        "MIDI variable-length quantity exceeds four bytes at offset " +
        offset.to_string(),
      )
    }

    let byte = bytes[cursor].to_int()
    value = (value << 7).lor(byte.land(0x7f))
    cursor += 1
    count += 1
    if byte.land(0x80) == 0 {
      if count > 1 && bytes[offset].to_int().land(0x7f) == 0 {
        raise MidiBinaryError::InvalidMidi(
          "non-canonical MIDI variable-length quantity at offset " +
          offset.to_string(),
        )
      }
      return (value, cursor)
    }
  }
  abort("unreachable")
}

///|
pub fn MidiFile::to_smf(self : MidiFile) -> Bytes raise MidiBinaryError {
  if self.tracks.length() == 0 {
    raise MidiBinaryError::InvalidMidi(
      "MIDI file must contain at least one track",
    )
  }

  let output : Array[Byte] = []
  output.push(b'M')
  output.push(b'T')
  output.push(b'h')
  output.push(b'd')
  append_u32_be(output, 6)

  let format = if self.tracks.length() <= 1 { 0 } else { 1 }
  append_u16_be(output, format)
  append_u16_be(output, self.tracks.length())
  validate_ppq(self.ppq)
  append_u16_be(output, self.ppq)

  for track in self.tracks {
    let payload = encode_track_payload(track)
    output.push(b'M')
    output.push(b'T')
    output.push(b'r')
    output.push(b'k')
    append_u32_be(output, payload.length())
    append_bytes(output, payload)
  }

  Bytes::from_array(output)
}

///|
pub fn MidiFile::from_smf(bytes : Bytes) -> MidiFile raise MidiBinaryError {
  if bytes.length() < 8 {
    raise MidiBinaryError::InvalidMidi("unexpected end of MIDI data at header")
  }
  expect_chunk_signature(bytes, 0, b"MThd", "header")
  if bytes.length() < 14 {
    raise MidiBinaryError::InvalidMidi("unexpected end of MIDI data at header")
  }

  let header_length = read_u32_be(bytes, 4, "header")
  if header_length != 6 {
    raise MidiBinaryError::InvalidMidi(
      "invalid MIDI header length " + header_length.to_string() + " at header",
    )
  }

  let format = read_u16_be(bytes, 8, "header")
  if format != 0 && format != 1 {
    raise MidiBinaryError::InvalidMidi(
      "unsupported MIDI format " + format.to_string() + " at header",
    )
  }

  let track_count = read_u16_be(bytes, 10, "header")
  if format == 0 && track_count != 1 {
    raise MidiBinaryError::InvalidMidi(
      "MIDI format 0 must declare exactly one track at header",
    )
  }
  let division = read_u16_be(bytes, 12, "header")
  if division <= 0 {
    raise MidiBinaryError::InvalidMidi(
      "MIDI division must be positive at header",
    )
  }
  if division.land(0x8000) != 0 {
    raise MidiBinaryError::InvalidMidi(
      "unsupported SMPTE MIDI division at header",
    )
  }

  let midi = MidiFile::new(division)
  let mut offset = 14
  for track_index in 0..<track_count {
    if offset + 8 > bytes.length() {
      raise MidiBinaryError::InvalidMidi(
        "unexpected end of MIDI data at track " + track_index.to_string(),
      )
    }
    expect_chunk_signature(
      bytes,
      offset,
      b"MTrk",
      "track " + track_index.to_string(),
    )
    let chunk_length = read_u32_be(
      bytes,
      offset + 4,
      "track " + track_index.to_string(),
    )
    let data_start = offset + 8
    let data_end = data_start + chunk_length
    if data_end > bytes.length() {
      raise MidiBinaryError::InvalidMidi(
        "unexpected end of MIDI data at track " + track_index.to_string(),
      )
    }

    let track = decode_track(
      bytes[data_start:data_end].to_owned(),
      track_index,
      data_start,
    )
    midi.tracks.push(track)
    offset = data_end
  }

  if offset != bytes.length() {
    raise MidiBinaryError::InvalidMidi(
      "trailing MIDI bytes after final track at offset " + offset.to_string(),
    )
  }

  midi
}

///|
fn validate_ppq(ppq : Int) -> Unit raise MidiBinaryError {
  if ppq <= 0 || ppq > 0xffff {
    raise MidiBinaryError::InvalidMidi(
      "MIDI division must be between 1 and 65535",
    )
  }
}

///|
fn append_bytes(output : Array[Byte], bytes : Bytes) -> Unit {
  for byte in bytes {
    output.push(byte)
  }
}

///|
fn append_u16_be(
  output : Array[Byte],
  value : Int,
) -> Unit raise MidiBinaryError {
  if value < 0 || value > 0xffff {
    raise MidiBinaryError::InvalidMidi(
      "integer " + value.to_string() + " does not fit in a 16-bit MIDI field",
    )
  }
  output.push((value >> 8).land(0xff).to_byte())
  output.push(value.land(0xff).to_byte())
}

///|
fn append_u32_be(
  output : Array[Byte],
  value : Int,
) -> Unit raise MidiBinaryError {
  if value < 0 {
    raise MidiBinaryError::InvalidMidi(
      "negative MIDI chunk length " + value.to_string(),
    )
  }
  output.push((value >> 24).land(0xff).to_byte())
  output.push((value >> 16).land(0xff).to_byte())
  output.push((value >> 8).land(0xff).to_byte())
  output.push(value.land(0xff).to_byte())
}

///|
fn read_u16_be(
  bytes : Bytes,
  offset : Int,
  context : String,
) -> Int raise MidiBinaryError {
  let view = bytes.get_view(start=offset, end=offset + 2)
  guard view is Some(slice) else {
    raise MidiBinaryError::InvalidMidi(
      "unexpected end of MIDI data at " + context,
    )
  }
  (slice[0].to_int() << 8).lor(slice[1].to_int())
}

///|
fn read_u32_be(
  bytes : Bytes,
  offset : Int,
  context : String,
) -> Int raise MidiBinaryError {
  let view = bytes.get_view(start=offset, end=offset + 4)
  guard view is Some(slice) else {
    raise MidiBinaryError::InvalidMidi(
      "unexpected end of MIDI data at " + context,
    )
  }
  (slice[0].to_int() << 24)
  .lor(slice[1].to_int() << 16)
  .lor(slice[2].to_int() << 8)
  .lor(slice[3].to_int())
}

///|
fn expect_chunk_signature(
  bytes : Bytes,
  offset : Int,
  signature : Bytes,
  context : String,
) -> Unit raise MidiBinaryError {
  let view = bytes.get_view(start=offset, end=offset + 4)
  guard view is Some(slice) else {
    raise MidiBinaryError::InvalidMidi(
      "unexpected end of MIDI data at " + context,
    )
  }
  if !slice.equal_to_bytes(signature) {
    raise MidiBinaryError::InvalidMidi(
      "invalid MIDI chunk signature at " + context,
    )
  }
}

///|
fn encode_track_payload(track : MidiTrack) -> Bytes raise MidiBinaryError {
  let output : Array[Byte] = []
  let mut running_status : Int? = None

  if track.name.length() > 0 {
    append_variable_length(output, 0)
    output.push(b'\xff')
    output.push(b'\x03')
    let name_bytes = @utf8.encode(track.name)
    append_variable_length(output, name_bytes.length())
    append_bytes(output, name_bytes)
    running_status = None
  }

  for event in track.events {
    validate_event_delta_time(event.delta_time)
    append_variable_length(output, event.delta_time)
    validate_channel_event_data(event.status, event.data1, event.data2)
    let status = event.status
    if running_status != Some(status) {
      output.push(status.to_byte())
      running_status = Some(status)
    }
    output.push(event.data1.to_byte())
    if channel_event_data_length(status) == 2 {
      output.push(event.data2.to_byte())
    }
  }

  append_variable_length(output, 0)
  output.push(b'\xff')
  output.push(b'/')
  output.push(b'\x00')
  Bytes::from_array(output)
}

///|
fn append_variable_length(
  output : Array[Byte],
  value : Int,
) -> Unit raise MidiBinaryError {
  for byte in encode_variable_length(value) {
    output.push(byte)
  }
}

///|
fn validate_event_delta_time(delta_time : Int) -> Unit raise MidiBinaryError {
  if delta_time < 0 {
    raise MidiBinaryError::InvalidMidi("MIDI delta time must be non-negative")
  }
}

///|
fn validate_channel_event_data(
  status : Int,
  data1 : Int,
  data2 : Int,
) -> Unit raise MidiBinaryError {
  let data_length = channel_event_data_length(status)
  if data1 < 0 || data1 > 127 {
    raise MidiBinaryError::InvalidMidi(
      "MIDI data byte must be between 0 and 127",
    )
  }
  if data2 < 0 || data2 > 127 {
    raise MidiBinaryError::InvalidMidi(
      "MIDI data byte must be between 0 and 127",
    )
  }
  if data_length == 1 && data2 != 0 {
    raise MidiBinaryError::InvalidMidi(
      "MIDI status 0x" +
      status.to_string(radix=16) +
      " cannot encode nonzero data2",
    )
  }
}

///|
fn decode_track(
  track_bytes : Bytes,
  track_index : Int,
  base_offset : Int,
) -> MidiTrack raise MidiBinaryError {
  let events : Array[MidiEvent] = []
  let mut name = ""
  let mut offset = 0
  let mut running_status : Int? = None
  let mut saw_end_of_track = false

  while offset < track_bytes.length() {
    let (delta_time, after_delta) = decode_variable_length(track_bytes, offset)
    let status_offset = after_delta
    if status_offset >= track_bytes.length() {
      raise MidiBinaryError::InvalidMidi(
        "unexpected end of MIDI data at track " + track_index.to_string(),
      )
    }

    let first = track_bytes[status_offset].to_int()
    if first == 0xFF {
      let meta_type_offset = status_offset + 1
      if meta_type_offset >= track_bytes.length() {
        raise MidiBinaryError::InvalidMidi(
          "unexpected end of MIDI data at track " + track_index.to_string(),
        )
      }
      let meta_type = track_bytes[meta_type_offset].to_int()
      let (meta_length, meta_data_offset) = decode_variable_length(
        track_bytes,
        meta_type_offset + 1,
      )
      let meta_end = meta_data_offset + meta_length
      if meta_end > track_bytes.length() {
        raise MidiBinaryError::InvalidMidi(
          "unexpected end of MIDI data at track " + track_index.to_string(),
        )
      }

      match meta_type {
        0x03 => {
          let payload = track_bytes[meta_data_offset:meta_end]
          name = decode_utf8_payload(
            payload,
            track_index,
            base_offset + meta_data_offset,
          )
          running_status = None
          offset = meta_end
        }
        0x2F => {
          if meta_length != 0 {
            raise MidiBinaryError::InvalidMidi(
              "end-of-track meta event must have length 0 in track " +
              track_index.to_string(),
            )
          }
          if meta_end != track_bytes.length() {
            raise MidiBinaryError::InvalidMidi(
              "trailing MIDI bytes after end-of-track in track " +
              track_index.to_string() +
              " at offset " +
              (base_offset + meta_end).to_string(),
            )
          }
          saw_end_of_track = true
          offset = meta_end
        }
        _ =>
          raise MidiBinaryError::InvalidMidi(
            "unsupported MIDI meta event 0x" +
            meta_type.to_string(radix=16) +
            " in track " +
            track_index.to_string(),
          )
      }
      continue
    }

    if first == 0xF0 || first == 0xF7 {
      raise MidiBinaryError::InvalidMidi(
        "unsupported MIDI sysex event in track " + track_index.to_string(),
      )
    }

    let (status, data_offset) = if first >= 0x80 {
      (first, status_offset + 1)
    } else {
      match running_status {
        Some(saved) => (saved, status_offset)
        None =>
          raise MidiBinaryError::InvalidMidi(
            "running status used before any channel status in track " +
            track_index.to_string(),
          )
      }
    }

    let data_length = channel_event_data_length(status)
    let data_end = data_offset + data_length
    if data_end > track_bytes.length() {
      raise MidiBinaryError::InvalidMidi(
        "unexpected end of MIDI data at track " + track_index.to_string(),
      )
    }

    let data1 = track_bytes[data_offset].to_int()
    let data2 = if data_length == 2 {
      track_bytes[data_offset + 1].to_int()
    } else {
      0
    }
    events.push(make_channel_event(delta_time, status, data1, data2))
    running_status = Some(status)
    offset = data_end
  }

  if !saw_end_of_track {
    raise MidiBinaryError::InvalidMidi(
      "missing end-of-track meta event in track " + track_index.to_string(),
    )
  }

  { name, events }
}

///|
fn decode_utf8_payload(
  payload : BytesView,
  track_index : Int,
  offset : Int,
) -> String raise MidiBinaryError {
  @utf8.decode(payload) catch {
    _ =>
      raise MidiBinaryError::InvalidMidi(
        "invalid UTF-8 in MIDI track " +
        track_index.to_string() +
        " at offset " +
        offset.to_string(),
      )
  }
}

///|
fn channel_event_data_length(status : Int) -> Int raise MidiBinaryError {
  let group = status.land(0xF0)
  if status < 0x80 || status > 0xEF {
    raise MidiBinaryError::InvalidMidi(
      "unsupported MIDI channel status 0x" + status.to_string(radix=16),
    )
  }
  match group {
    0x80 | 0x90 | 0xA0 | 0xB0 | 0xE0 => 2
    0xC0 | 0xD0 => 1
    _ =>
      raise MidiBinaryError::InvalidMidi(
        "unsupported MIDI channel status 0x" + status.to_string(radix=16),
      )
  }
}

///|
fn make_channel_event(
  delta_time : Int,
  status : Int,
  data1 : Int,
  data2 : Int,
) -> MidiEvent raise MidiBinaryError {
  validate_event_delta_time(delta_time)
  validate_channel_event_data(status, data1, data2)
  let normalized_status = if status.land(0xF0) == 0x90 && data2 == 0 {
    0x80 + status.land(0x0F)
  } else {
    status
  }
  { delta_time, status: normalized_status, data1, data2 }
}
