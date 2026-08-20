///|
pub(all) enum MotionType {
  Parallel
  Contrary
  Oblique
  Similar
  Static
  MissingVoice
} derive(Eq, Debug)

///|
pub fn MotionType::to_string(self : MotionType) -> String {
  match self {
    Parallel => "Parallel"
    Contrary => "Contrary"
    Oblique => "Oblique"
    Similar => "Similar"
    Static => "Static"
    MissingVoice => "MissingVoice"
  }
}

///|
pub impl Show for MotionType with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
fn motion_delta(note1 : Note, note2 : Note) -> Int {
  note2.to_midi() - note1.to_midi()
}

///|
pub fn classify_voice_motion(
  lower_start~ : Note?,
  lower_end~ : Note?,
  upper_start~ : Note?,
  upper_end~ : Note?,
) -> MotionType {
  match (lower_start, lower_end, upper_start, upper_end) {
    (Some(ls), Some(le), Some(us), Some(ue)) => {
      let lower_delta = motion_delta(ls, le)
      let upper_delta = motion_delta(us, ue)

      if lower_delta == 0 && upper_delta == 0 {
        Static
      } else if lower_delta == 0 || upper_delta == 0 {
        Oblique
      } else if (lower_delta > 0 && upper_delta < 0) ||
        (lower_delta < 0 && upper_delta > 0) {
        Contrary
      } else {
        let start_interval = us.to_midi() - ls.to_midi()
        let end_interval = ue.to_midi() - le.to_midi()
        if start_interval == end_interval {
          Parallel
        } else {
          Similar
        }
      }
    }
    _ => MissingVoice
  }
}
