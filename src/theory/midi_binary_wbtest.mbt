///|
test "channel event data lengths match the MIDI subset" {
  inspect(channel_event_data_length(0x80), content="2")
  inspect(channel_event_data_length(0x90), content="2")
  inspect(channel_event_data_length(0xA0), content="2")
  inspect(channel_event_data_length(0xB0), content="2")
  inspect(channel_event_data_length(0xC0), content="1")
  inspect(channel_event_data_length(0xD0), content="1")
  inspect(channel_event_data_length(0xE0), content="2")
}

///|
test "channel event normalization turns note-on velocity zero into note-off" {
  let event = make_channel_event(16, 0x90, 60, 0)
  inspect(event.delta_time, content="16")
  inspect(event.status, content="128")
  inspect(event.data1, content="60")
  inspect(event.data2, content="0")
}
