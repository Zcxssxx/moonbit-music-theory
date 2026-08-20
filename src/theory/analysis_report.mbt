///|
pub(all) struct PitchHistogram {
  counts : Array[Int]
} derive(Eq, Debug)

///|
pub(all) struct RhythmSummary {
  meter_supported : Bool
  beat_ticks : Int
  beat_count : Int
  average_duration_ticks : Int
  density_per_beat_milli : Int
  syncopation : Int
  on_beat_attacks : Int
  off_beat_attacks : Int
} derive(Eq, Debug)

///|
pub(all) struct HarmonySummary {
  symbol_count : Int
  cadence : CadenceKind
  tonic_count : Int
  predominant_count : Int
  dominant_count : Int
  ambiguous_count : Int
  finding_count : Int
} derive(Eq, Debug)

///|
pub(all) struct ScoreReport {
  duration_ticks : Int
  track_count : Int
  note_event_count : Int
  chord_event_count : Int
  pitch_histogram : PitchHistogram
  register_min : Note?
  register_max : Note?
  melodic_intervals : Array[Int]
  rhythm_summary : RhythmSummary
  harmony_summary : HarmonySummary
  voice_leading_warning_count : Int
} derive(Eq, Debug)

///|
pub fn analyze_score(score : Score, key : Key) -> ScoreReport {
  let note_events = collect_note_events(score)
  let chord_events = collect_chord_events(score)
  let duration_ticks = score.duration_ticks()
  let note_event_count = note_events.length()
  let rhythm_summary = build_rhythm_summary(score, note_events, duration_ticks)

  {
    duration_ticks,
    track_count: score.tracks.length(),
    note_event_count,
    chord_event_count: chord_events.length(),
    pitch_histogram: build_pitch_histogram(note_events),
    register_min: find_register_note(note_events, find_lowest=true),
    register_max: find_register_note(note_events, find_lowest=false),
    melodic_intervals: collect_melodic_intervals(score),
    rhythm_summary,
    harmony_summary: build_harmony_summary(key, chord_events),
    voice_leading_warning_count: count_voice_leading_warnings(score),
  }
}

///|
pub fn ScoreReport::text(self : ScoreReport) -> String {
  self.to_text()
}

///|
pub fn ScoreReport::to_text(self : ScoreReport) -> String {
  let register = if self.register_min is Some(min_note) &&
    self.register_max is Some(max_note) {
    "\{min_note.to_string()}..\{max_note.to_string()}"
  } else {
    "none"
  }
  let lines = [
    "Score report",
    "duration_ticks: \{self.duration_ticks}",
    "tracks: \{self.track_count}",
    "note_events: \{self.note_event_count}",
    "chord_events: \{self.chord_event_count}",
    "pitch-class histogram: \{self.pitch_histogram}",
    "register: \{register}",
    "melodic_intervals: \{format_int_array(self.melodic_intervals)}",
    "rhythm: meter_supported=\{self.rhythm_summary.meter_supported} beat_ticks=\{self.rhythm_summary.beat_ticks} beats=\{self.rhythm_summary.beat_count} average_duration_ticks=\{self.rhythm_summary.average_duration_ticks} density_per_beat_milli=\{self.rhythm_summary.density_per_beat_milli} syncopation=\{self.rhythm_summary.syncopation} on_beat=\{self.rhythm_summary.on_beat_attacks} off_beat=\{self.rhythm_summary.off_beat_attacks}",
    "harmony: symbols=\{self.harmony_summary.symbol_count} cadence=\{self.harmony_summary.cadence} tonic=\{self.harmony_summary.tonic_count} predominant=\{self.harmony_summary.predominant_count} dominant=\{self.harmony_summary.dominant_count} ambiguous=\{self.harmony_summary.ambiguous_count} findings=\{self.harmony_summary.finding_count}",
    "voice_leading_warnings: \{self.voice_leading_warning_count}",
  ]
  lines.join("\n") + "\n"
}

///|
pub fn PitchHistogram::to_string(self : PitchHistogram) -> String {
  format_int_array(self.counts)
}

///|
pub impl Show for PitchHistogram with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
fn collect_note_events(score : Score) -> Array[NoteEvent] {
  let events : Array[NoteEvent] = []
  for track in score.tracks {
    for event in track.events {
      events.push(event)
    }
  }
  events
}

///|
fn collect_chord_events(score : Score) -> Array[ChordEvent] {
  let events : Array[ChordEvent] = []
  for track in score.tracks {
    for event in track.chord_events {
      insert_chord_event_sorted(events, event)
    }
  }
  events
}

///|
fn build_pitch_histogram(note_events : Array[NoteEvent]) -> PitchHistogram {
  let counts = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  for event in note_events {
    let pitch_class = normalize_pitch_class(event.note.to_midi())
    counts[pitch_class] = counts[pitch_class] + 1
  }
  { counts, }
}

///|
fn find_register_note(
  note_events : Array[NoteEvent],
  find_lowest~ : Bool,
) -> Note? {
  if note_events.length() == 0 {
    return None
  }

  let mut best = note_events[0].note
  for event in note_events {
    let midi = event.note.to_midi()
    let best_midi = best.to_midi()
    if find_lowest {
      if midi < best_midi {
        best = event.note
      }
    } else if midi > best_midi {
      best = event.note
    }
  }
  Some(best)
}

///|
fn collect_melodic_intervals(score : Score) -> Array[Int] {
  let intervals : Array[Int] = []
  for track in score.tracks {
    if track.events.length() < 2 {
      continue
    }
    for i in 0..<(track.events.length() - 1) {
      let left = track.events[i].note.to_midi()
      let right = track.events[i + 1].note.to_midi()
      intervals.push((right - left).abs())
    }
  }
  intervals
}

///|
fn compute_average_duration_ticks(note_events : Array[NoteEvent]) -> Int {
  if note_events.length() == 0 {
    return 0
  }

  let mut total = 0
  for event in note_events {
    total += event.duration_ticks
  }
  total / note_events.length()
}

///|
fn compute_beat_count(duration_ticks : Int, beat_ticks : Int) -> Int {
  if duration_ticks <= 0 || beat_ticks <= 0 {
    return 0
  }
  (duration_ticks + beat_ticks - 1) / beat_ticks
}

///|
fn compute_density_per_beat_milli(
  note_event_count : Int,
  beat_count : Int,
) -> Int {
  if note_event_count <= 0 || beat_count <= 0 {
    return 0
  }
  note_event_count * 1000 / beat_count
}

///|
fn build_rhythm_summary(
  score : Score,
  note_events : Array[NoteEvent],
  duration_ticks : Int,
) -> RhythmSummary {
  let average_duration_ticks = compute_average_duration_ticks(note_events)
  match supported_report_grid(score) {
    Some(grid) => {
      let beat_count = compute_beat_count(duration_ticks, grid.beat_ticks)
      {
        meter_supported: true,
        beat_ticks: grid.beat_ticks,
        beat_count,
        average_duration_ticks,
        density_per_beat_milli: compute_density_per_beat_milli(
          note_events.length(),
          beat_count,
        ),
        syncopation: compute_syncopation(note_events, grid),
        on_beat_attacks: count_on_beat_attacks(note_events, grid.beat_ticks),
        off_beat_attacks: count_off_beat_attacks(note_events, grid.beat_ticks),
      }
    }
    None =>
      {
        meter_supported: false,
        beat_ticks: 0,
        beat_count: 0,
        average_duration_ticks,
        density_per_beat_milli: 0,
        syncopation: 0,
        on_beat_attacks: 0,
        off_beat_attacks: 0,
      }
  }
}

///|
fn supported_report_grid(score : Score) -> BeatGrid? {
  try
    BeatGrid::new(
      ppq=score.ppq,
      subdivision=4,
      time_signature=score.time_signature,
    )
  catch {
    _ => None
  } noraise {
    grid => Some(grid)
  }
}

///|
fn count_on_beat_attacks(
  note_events : Array[NoteEvent],
  beat_ticks : Int,
) -> Int {
  if beat_ticks <= 0 {
    return 0
  }

  let mut count = 0
  for event in note_events {
    if event.start_tick % beat_ticks == 0 {
      count = count + 1
    }
  }
  count
}

///|
fn count_off_beat_attacks(
  note_events : Array[NoteEvent],
  beat_ticks : Int,
) -> Int {
  if beat_ticks <= 0 {
    return 0
  }

  let mut count = 0
  for event in note_events {
    if event.start_tick % beat_ticks != 0 {
      count = count + 1
    }
  }
  count
}

///|
fn compute_syncopation(note_events : Array[NoteEvent], grid : BeatGrid) -> Int {
  match attack_gap_pattern(note_events) {
    Some(pattern) => analyze_syncopation(pattern, grid)
    None => 0
  }
}

///|
fn attack_gap_pattern(note_events : Array[NoteEvent]) -> RhythmPattern? {
  if note_events.length() == 0 {
    return try RhythmPattern::new([]) catch {
      _ => None
    } noraise {
      pattern => Some(pattern)
    }
  }

  let sorted = sort_note_events_by_start(note_events)
  if sorted.length() == 0 {
    return None
  }
  let durations : Array[Int] = []
  if sorted[0].start_tick > 0 {
    durations.push(sorted[0].start_tick)
  }
  for i in 1..<sorted.length() {
    durations.push(sorted[i].start_tick - sorted[i - 1].start_tick)
  }
  durations.push(0)
  try RhythmPattern::new(durations) catch {
    _ => None
  } noraise {
    pattern => Some(pattern)
  }
}

///|
fn build_harmony_summary(
  key : Key,
  chord_events : Array[ChordEvent],
) -> HarmonySummary {
  if chord_events.length() == 0 {
    return {
      symbol_count: 0,
      cadence: Undetermined,
      tonic_count: 0,
      predominant_count: 0,
      dominant_count: 0,
      ambiguous_count: 0,
      finding_count: 0,
    }
  }

  let symbols = chord_events.map(fn(event) { chord_event_symbol(event) })
  let analysis = analyze_harmony(key, symbols)
  let mut tonic_count = 0
  let mut predominant_count = 0
  let mut dominant_count = 0
  let mut ambiguous_count = 0

  for function in analysis.functions {
    match function {
      Tonic => tonic_count = tonic_count + 1
      Predominant => predominant_count = predominant_count + 1
      Dominant => dominant_count = dominant_count + 1
      Ambiguous => ambiguous_count = ambiguous_count + 1
    }
  }

  {
    symbol_count: symbols.length(),
    cadence: classify_cadence_context(analysis),
    tonic_count,
    predominant_count,
    dominant_count,
    ambiguous_count,
    finding_count: analysis.findings.length(),
  }
}

///|
fn chord_event_symbol(event : ChordEvent) -> String {
  let root = note_name_without_octave(event.root)
  match event.chord_type {
    MajorTriad => root
    MinorTriad => root + "m"
    DiminishedTriad => root + "dim"
    AugmentedTriad => root + "aug"
    MajorSeventh => root + "maj7"
    DominantSeventh => root + "7"
    MinorSeventh => root + "m7"
    HalfDiminishedSeventh => root + "m7b5"
    DiminishedSeventh => root + "dim7"
    _ => root + "[" + event.chord_type.to_string() + "]"
  }
}

///|
fn note_name_without_octave(note : Note) -> String {
  note.letter.to_string() + note.accidental.to_string()
}

///|
fn count_voice_leading_warnings(score : Score) -> Int {
  let mut total = 0
  if score.tracks.length() < 2 {
    return total
  }

  for i in 0..<(score.tracks.length() - 1) {
    let left_events = score.tracks[i].events
    let right_events = score.tracks[i + 1].events
    // Conservative scope: reuse first-species diagnostics only when the two
    // tracks already form exact note-to-note time pairs. Misaligned tracks are
    // skipped rather than inventing warnings from array index alone.
    if note_events_share_counterpoint_timing(left_events, right_events) {
      let left = left_events.map(fn(event) { event.note })
      let right = right_events.map(fn(event) { event.note })
      total += check_first_species(left, right).length()
    }
  }
  total
}

///|
fn note_events_share_counterpoint_timing(
  left : Array[NoteEvent],
  right : Array[NoteEvent],
) -> Bool {
  if left.length() == 0 || left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if left[i].start_tick != right[i].start_tick ||
      left[i].duration_ticks != right[i].duration_ticks {
      return false
    }
  }
  true
}

///|
fn sort_note_events_by_start(
  note_events : Array[NoteEvent],
) -> Array[NoteEvent] {
  let sorted : Array[NoteEvent] = []
  for event in note_events {
    insert_note_event_sorted(sorted, event)
  }
  sorted
}

///|
fn insert_note_event_sorted(
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
fn insert_chord_event_sorted(
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
fn normalize_pitch_class(midi : Int) -> Int {
  (midi % 12 + 12) % 12
}

///|
fn format_int_array(values : Array[Int]) -> String {
  let mut result = "["
  for i in 0..<values.length() {
    if i > 0 {
      result = result + ", "
    }
    result = result + values[i].to_string()
  }
  result + "]"
}
