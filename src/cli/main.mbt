fn print_usage() -> Unit {
  println("MoonBit Music Theory CLI Toolbox")
  println("Usage:")
  println("  moon run src/cli -- chord <symbol>                   - Query chord notes (e.g. Cmaj7)")
  println("  moon run src/cli -- scale <root> <type>              - Generate scale notes (e.g. C major)")
  println("  moon run src/cli -- transpose <note> <interval>      - Transpose a note by an interval (e.g. C4 M3)")
  println("  moon run src/cli -- roman <key_root> <key_type> <chord> - Analyze roman numeral degree (e.g. C major G7)")
}

fn main {
  let args = @env.args()
  if args.length() < 2 {
    print_usage()
    return
  }

  let cmd = args[1]
  match cmd {
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
          
          println("{\"root\":\"\{root}\",\"type\":\"\{chord_type}\",\"notes\":\{notes_json}}")
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
        let is_digit = last_char.to_int() - '0'.to_int() >= 0 && last_char.to_int() - '0'.to_int() <= 9
        if is_digit { root_str } else { root_str + "4" }
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
      
      println("{\"root\":\"\{root}\",\"type\":\"\{scale_type}\",\"notes\":\{notes_json}}")
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
      println("{\"note\":\"\{note}\",\"interval\":\"\{interval}\",\"result\":\"\{res_note}\"}")
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
        let is_digit = last_char.to_int() - '0'.to_int() >= 0 && last_char.to_int() - '0'.to_int() <= 9
        if is_digit { key_root_str } else { key_root_str + "4" }
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
      
      let key = @theory.Key::new(key_root.letter, key_root.accidental, key_scale_type)
      match key.analyze_chord(chord_str) {
        Ok(r) => {
          println("{\"key\":\"\{key}\",\"chord\":\"\{chord_str}\",\"result\":\"\{r}\"}")
        }
        Err(err) => println("Error: \{err}")
      }
    }
    _ => {
      println("Error: Unknown command \{cmd}")
      print_usage()
    }
  }
}
