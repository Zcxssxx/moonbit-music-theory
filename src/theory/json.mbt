pub impl ToJson for Note with fn to_json(self : Note) -> Json {
  Json::string(self.to_string())
}

pub impl @json.FromJson for Note with fn from_json(json, path) {
  match json {
    String(s) => match Note::parse(s) {
      Ok(n) => n
      Err(err) => raise @json.JsonDecodeError((path, "Note::from_json: " + err))
    }
    _ => raise @json.JsonDecodeError((path, "Note::from_json: expected string"))
  }
}

pub impl ToJson for Interval with fn to_json(self : Interval) -> Json {
  Json::string(self.to_string())
}

pub impl @json.FromJson for Interval with fn from_json(json, path) {
  match json {
    String(s) => match Interval::parse(s) {
      Ok(inv) => inv
      Err(err) => raise @json.JsonDecodeError((path, "Interval::from_json: " + err))
    }
    _ => raise @json.JsonDecodeError((path, "Interval::from_json: expected string"))
  }
}

pub impl ToJson for Key with fn to_json(self : Key) -> Json {
  Json::string(self.to_string())
}

pub impl @json.FromJson for Key with fn from_json(json, path) {
  match json {
    String(s) => {
      // Key parse helper: "C major"
      let parts = s.split(" ").collect()
      if parts.length() != 2 {
        raise @json.JsonDecodeError((path, "Key::from_json: expected '<root> <type>' format"))
      }
      let note_part = parts[0].to_owned()
      let type_part = parts[1].to_owned()
      let root_note = match Note::parse(note_part + "4") { // temporary octave 4 to reuse parse
        Ok(n) => n
        Err(err) => raise @json.JsonDecodeError((path, "Key::from_json: " + err))
      }
      let scale_type = match ScaleType::parse(type_part) {
        Ok(t) => t
        Err(err) => raise @json.JsonDecodeError((path, "Key::from_json: " + err))
      }
      Key::new(root_note.letter, root_note.accidental, scale_type)
    }
    _ => raise @json.JsonDecodeError((path, "Key::from_json: expected string"))
  }
}
