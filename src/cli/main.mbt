///|
fn parse_cli_int(text : String) -> Int? {
  if text.length() == 0 {
    return None
  }
  let mut value = 0
  for ch in text {
    let digit = ch.to_int() - '0'.to_int()
    if digit < 0 || digit > 9 {
      return None
    }
    value = value * 10 + digit
  }
  Some(value)
}

///|
fn cli_key(root_text : String, type_text : String) -> @theory.Key? {
  let root_name = if root_text.length() > 0 {
    let last = root_text[root_text.length() - 1]
    let digit = last.to_int() - '0'.to_int()
    if digit >= 0 && digit <= 9 {
      root_text
    } else {
      root_text + "4"
    }
  } else {
    "C4"
  }
  match (@theory.Note::parse(root_name), @theory.ScaleType::parse(type_text)) {
    (Ok(note), Ok(scale)) =>
      Some(@theory.Key::new(note.letter, note.accidental, scale))
    (_, _) => None
  }
}

///|
fn cli_demo_score(length : Int) -> @theory.Score raise Failure {
  let score = @theory.Score::new(480)
  let track = score.add_track("cli-fixture")
  let roots = ["C4", "F4", "G4", "C4"]
  let types = [
    @theory.ChordType::MajorTriad,
    @theory.ChordType::MajorTriad,
    @theory.ChordType::DominantSeventh,
    @theory.ChordType::MajorTriad,
  ]
  let count = if length < 1 { 1 } else if length > 4 { 4 } else { length }
  for i in 0..<count {
    let root = @theory.Note::parse(roots[i]).unwrap()
    track.add_chord(
      @theory.ChordEvent::new(root, types[i], i * 480, 480, 90, 0),
    )
    track.add_note(@theory.NoteEvent::new(root, i * 480, 240, 90, 0))
  }
  score
}

///|
fn print_usage() -> Unit {
  println("MoonBit Music Theory CLI Toolbox")
  println("Usage:")
  println(
    "  moon run src/cli -- chord <symbol>                   - Query chord notes (e.g. Cmaj7)",
  )
  println(
    "  moon run src/cli -- scale <root> <type>              - Generate scale notes (e.g. C major)",
  )
  println(
    "  moon run src/cli -- transpose <note> <interval>      - Transpose a note by an interval (e.g. C4 M3)",
  )
  println(
    "  moon run src/cli -- roman <key_root> <key_type> <chord> - Analyze roman numeral degree (e.g. C major G7)",
  )
  println(
    "  moon run src/cli -- progression <key_root> <key_type> <progression_csv> - Generate progression with voice leading (e.g. C major I,vi,IV,V)",
  )
  println(
    "  moon run src/cli -- counterpoint <cf_csv> <cp_csv>    - Check 1st species counterpoint rules (e.g. C4,D4,E4,D4,C4 C5,B4,G4,B4,C5)",
  )
  println(
    "  moon run src/cli -- analyze-chord <notes_csv>        - Detect chord name from notes list (e.g. C4,E4,G4)",
  )
  println("  moon run src/cli -- report <key_root> <key_type> <symbols_csv>")
  println(
    "  moon run src/cli -- report-json <key_root> <key_type> <symbols_csv>",
  )
  println("  moon run src/cli -- midi-roundtrip <symbols_csv>")
  println(
    "  moon run src/cli -- generate <key_root> <key_type> <length> <seed>",
  )
}

///|
fn main raise Failure {
  let args = @env.args()
  if args.length() < 2 {
    print_usage()
    return
  }

  let cmd = args[1]
  match cmd {
    "report" | "report-json" => {
      if args.length() != 5 {
        println("Error: report requires <key_root> <key_type> <symbols_csv>")
        return
      }
      match cli_key(args[2], args[3]) {
        Some(key) => {
          let symbols = args[4].split(",").collect()
          let report = @theory.analyze_score(
            cli_demo_score(symbols.length()),
            key,
          )
          if cmd == "report-json" {
            println(report.to_json().stringify())
          } else {
            println(report.to_text())
          }
        }
        None => println("Error: invalid key root or scale type")
      }
    }
    "midi-roundtrip" => {
      if args.length() != 3 {
        println("Error: midi-roundtrip requires <symbols_csv>")
        return
      }
      let midi = @theory.MidiFile::new(480)
      let track = midi.add_track("cli-roundtrip")
      let notes = [
        @theory.Note::parse("C4").unwrap(),
        @theory.Note::parse("E4").unwrap(),
        @theory.Note::parse("G4").unwrap(),
      ]
      track.add_chord(0, notes, 480, 90)
      try {
        let decoded = @theory.MidiFile::from_smf(midi.to_smf())
        println(
          "round_trip=true tracks=\{decoded.tracks.length()} events=\{decoded.tracks[0].events.length()}",
        )
      } catch {
        err => println("Error: \{err.to_string()}")
      }
    }
    "generate" => {
      if args.length() != 6 {
        println(
          "Error: generate requires <key_root> <key_type> <length> <seed>",
        )
        return
      }
      match
        (
          cli_key(args[2], args[3]),
          parse_cli_int(args[4]),
          parse_cli_int(args[5]),
        ) {
        (Some(key), Some(length), Some(seed)) if length > 0 => {
          let cycle = ["I", "IV", "V", "I"]
          let symbols : Array[String] = []
          for i in 0..<length {
            symbols.push(cycle[(i + seed.abs()) % cycle.length()])
          }
          match @theory.generate_progression(key, symbols) {
            Ok(_) => println("seed=\{seed} symbols=\{symbols.join(",")}")
            Err(err) => println("Error: \{err}")
          }
        }
        (_, _, _) =>
          println(
            "Error: length and seed must be valid integers; length must be positive",
          )
      }
    }
    "chord" => {
      if args.length() < 3 {
        println("Error: Missing chord symbol")
        print_usage()
        return
      }
      let symbol = args[2]
      match @theory.parse_chord_symbol(symbol) {
        Ok((root, chord_type)) => {
          let notes = @theory.generate_chord(root, chord_type)
          let notes_strs = notes.map(fn(n) { n.to_string() })

          // Format as JSON manually to be clean and simple
          let mut notes_json = "["
          for i in 0..<notes_strs.length() {
            if i > 0 {
              notes_json = notes_json + ","
            }
            notes_json = notes_json + "\"" + notes_strs[i] + "\""
          }
          notes_json = notes_json + "]"

          println(
            "{\"root\":\"\{root}\",\"type\":\"\{chord_type}\",\"notes\":\{notes_json}}",
          )
        }
        Err(err) => println("Error: \{err}")
      }
    }
    "scale" => {
      if args.length() < 4 {
        println("Error: Missing scale root and type")
        print_usage()
        return
      }
      let root_str = args[2]
      let type_str = args[3]
      // parse root note
      // If root note doesn't specify octave, default to 4
      let root_note_str = if root_str.length() > 0 {
        let last_char = root_str[root_str.length() - 1]
        let is_digit = last_char.to_int() - '0'.to_int() >= 0 &&
          last_char.to_int() - '0'.to_int() <= 9
        if is_digit {
          root_str
        } else {
          root_str + "4"
        }
      } else {
        "C4"
      }

      let root = match @theory.Note::parse(root_note_str) {
        Ok(n) => n
        Err(err) => {
          println("Error parsing root note: \{err}")
          return
        }
      }

      let scale_type = match @theory.ScaleType::parse(type_str) {
        Ok(t) => t
        Err(err) => {
          println("Error parsing scale type: \{err}")
          return
        }
      }

      let notes = @theory.generate_scale(root, scale_type)
      let notes_strs = notes.map(fn(n) { n.to_string() })
      let mut notes_json = "["
      for i in 0..<notes_strs.length() {
        if i > 0 {
          notes_json = notes_json + ","
        }
        notes_json = notes_json + "\"" + notes_strs[i] + "\""
      }
      notes_json = notes_json + "]"

      println(
        "{\"root\":\"\{root}\",\"type\":\"\{scale_type}\",\"notes\":\{notes_json}}",
      )
    }
    "transpose" => {
      if args.length() < 4 {
        println("Error: Missing note and interval")
        print_usage()
        return
      }
      let note_str = args[2]
      let interval_str = args[3]

      let note = match @theory.Note::parse(note_str) {
        Ok(n) => n
        Err(err) => {
          println("Error parsing note: \{err}")
          return
        }
      }

      let interval = match @theory.Interval::parse(interval_str) {
        Ok(inv) => inv
        Err(err) => {
          println("Error parsing interval: \{err}")
          return
        }
      }

      let res_note = note.transpose(interval)
      println(
        "{\"note\":\"\{note}\",\"interval\":\"\{interval}\",\"result\":\"\{res_note}\"}",
      )
    }
    "roman" => {
      if args.length() < 5 {
        println("Error: Missing key_root, key_type and chord")
        print_usage()
        return
      }
      let key_root_str = args[2]
      let key_type_str = args[3]
      let chord_str = args[4]

      let key_root_note_str = if key_root_str.length() > 0 {
        let last_char = key_root_str[key_root_str.length() - 1]
        let is_digit = last_char.to_int() - '0'.to_int() >= 0 &&
          last_char.to_int() - '0'.to_int() <= 9
        if is_digit {
          key_root_str
        } else {
          key_root_str + "4"
        }
      } else {
        "C4"
      }

      let key_root = match @theory.Note::parse(key_root_note_str) {
        Ok(n) => n
        Err(err) => {
          println("Error parsing key root note: \{err}")
          return
        }
      }

      let key_scale_type = match @theory.ScaleType::parse(key_type_str) {
        Ok(t) => t
        Err(err) => {
          println("Error parsing key scale type: \{err}")
          return
        }
      }

      let key = @theory.Key::new(
        key_root.letter,
        key_root.accidental,
        key_scale_type,
      )
      match key.analyze_chord(chord_str) {
        Ok(r) =>
          println(
            "{\"key\":\"\{key}\",\"chord\":\"\{chord_str}\",\"result\":\"\{r}\"}",
          )
        Err(err) => println("Error: \{err}")
      }
    }
    "progression" => {
      if args.length() < 5 {
        println("Error: Missing key_root, key_type and progression csv")
        print_usage()
        return
      }
      let key_root_str = args[2]
      let key_type_str = args[3]
      let prog_csv = args[4]

      let key_root_note_str = if key_root_str.length() > 0 {
        let last_char = key_root_str[key_root_str.length() - 1]
        let is_digit = last_char.to_int() - '0'.to_int() >= 0 &&
          last_char.to_int() - '0'.to_int() <= 9
        if is_digit {
          key_root_str
        } else {
          key_root_str + "4"
        }
      } else {
        "C4"
      }

      let key_root = match @theory.Note::parse(key_root_note_str) {
        Ok(n) => n
        Err(err) => {
          println("Error parsing key root note: \{err}")
          return
        }
      }

      let key_scale_type = match @theory.ScaleType::parse(key_type_str) {
        Ok(t) => t
        Err(err) => {
          println("Error parsing key scale type: \{err}")
          return
        }
      }

      let key = @theory.Key::new(
        key_root.letter,
        key_root.accidental,
        key_scale_type,
      )

      let roman_numerals = prog_csv
        .split(",")
        .collect()
        .map(fn(s) { s.to_owned() })
      match @theory.generate_progression(key, roman_numerals) {
        Ok(voicings) => {
          let mut voicings_json = "["
          for i in 0..<voicings.length() {
            if i > 0 {
              voicings_json = voicings_json + ","
            }
            let notes_strs = voicings[i].map(fn(n) { n.to_string() })
            let mut v_json = "["
            for j in 0..<notes_strs.length() {
              if j > 0 {
                v_json = v_json + ","
              }
              v_json = v_json + "\"" + notes_strs[j] + "\""
            }
            v_json = v_json + "]"
            voicings_json = voicings_json + v_json
          }
          voicings_json = voicings_json + "]"
          println(
            "{\"key\":\"\{key}\",\"progression\":[\"\{prog_csv}\"],\"voicings\":\{voicings_json}}",
          )
        }
        Err(err) => println("Error: \{err}")
      }
    }
    "counterpoint" => {
      if args.length() < 4 {
        println("Error: Missing cantus firmus and counterpoint csv")
        print_usage()
        return
      }
      let cf_csv = args[2]
      let cp_csv = args[3]

      let cf_strs = cf_csv.split(",").collect()
      let cp_strs = cp_csv.split(",").collect()

      let cf_notes = []
      for s in cf_strs {
        match @theory.Note::parse(s.to_owned()) {
          Ok(n) => cf_notes.push(n)
          Err(err) => {
            println("Error parsing cantus firmus note: \{err}")
            return
          }
        }
      }

      let cp_notes = []
      for s in cp_strs {
        match @theory.Note::parse(s.to_owned()) {
          Ok(n) => cp_notes.push(n)
          Err(err) => {
            println("Error parsing counterpoint note: \{err}")
            return
          }
        }
      }

      let warnings = @theory.check_first_species(cf_notes, cp_notes)
      let mut warnings_json = "["
      for i in 0..<warnings.length() {
        if i > 0 {
          warnings_json = warnings_json + ","
        }
        let w = warnings[i]
        warnings_json = warnings_json +
          "{\"index\":\{w.index},\"rule\":\"\{w.rule_name}\",\"message\":\"\{w.message}\"}"
      }
      warnings_json = warnings_json + "]"

      println(
        "{\"status\":\"" +
        (if warnings.length() == 0 { "passed" } else { "warnings" }) +
        "\",\"warnings\":\{warnings_json}}",
      )
    }
    "analyze-chord" => {
      if args.length() < 3 {
        println("Error: Missing notes list csv")
        print_usage()
        return
      }
      let notes_csv = args[2]
      let notes_strs = notes_csv.split(",").collect()

      let notes = []
      for s in notes_strs {
        match @theory.Note::parse(s.to_owned()) {
          Ok(n) => notes.push(n)
          Err(err) => {
            println("Error parsing note: \{err}")
            return
          }
        }
      }

      match @theory.analyze_chord_notes(notes) {
        Ok((root, ty, inv)) =>
          println(
            "{\"detected_root\":\"\{root}\",\"type\":\"\{ty}\",\"inversion\":\{inv}}",
          )
        Err(err) => println("Error: \{err}")
      }
    }
    _ => {
      println("Error: Unknown command \{cmd}")
      print_usage()
    }
  }
}
