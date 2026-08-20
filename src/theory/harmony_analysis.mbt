///|
pub(all) enum HarmonyFunction {
  Tonic
  Predominant
  Dominant
  Ambiguous
} derive(Eq, Debug)

///|
pub(all) enum CadenceKind {
  Authentic
  Plagal
  Deceptive
  Half
  Undetermined
} derive(Eq, Debug)

///|
pub(all) enum HarmonyFindingKind {
  Cadence(CadenceKind)
  Ambiguity
  InvalidInput
} derive(Eq, Debug)

///|
pub(all) struct HarmonyFinding {
  index : Int
  symbol : String
  kind : HarmonyFindingKind
  detail : String
} derive(Eq, Debug)

///|
pub(all) struct HarmonyAnalysis {
  key : Key
  symbols : Array[String]
  romans : Array[String]
  functions : Array[HarmonyFunction]
  findings : Array[HarmonyFinding]
} derive(Eq, Debug)

///|
pub fn CadenceKind::to_string(self : CadenceKind) -> String {
  match self {
    Authentic => "Authentic"
    Plagal => "Plagal"
    Deceptive => "Deceptive"
    Half => "Half"
    Undetermined => "Undetermined"
  }
}

///|
pub impl Show for CadenceKind with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
fn is_chromatic_roman(roman : String) -> Bool {
  roman.length() > 0 &&
  (roman[0] == 'b'.to_int().to_uint16() || roman[0] == '#'.to_int().to_uint16())
}

///|
fn to_harmony_function(roman : String) -> HarmonyFunction {
  if roman.length() == 0 || is_chromatic_roman(roman) {
    return Ambiguous
  }

  match get_chord_function(roman) {
    ChordFunction::Tonic => Tonic
    ChordFunction::Subdominant => Predominant
    ChordFunction::Dominant => Dominant
    ChordFunction::Unknown => Ambiguous
  }
}

///|
fn ambiguity_detail_for(key : Key) -> String {
  "roman harmony does not map to a stable function in \{key.to_string()}"
}

///|
fn detect_cadence_kind(roman1 : String, roman2 : String) -> CadenceKind {
  match detect_cadence(roman1, roman2) {
    "Authentic Cadence (AC)" => Authentic
    "Plagal Cadence (PC)" => Plagal
    "Deceptive Cadence (DC)" => Deceptive
    "Half Cadence (HC)" => Half
    _ => Undetermined
  }
}

///|
fn is_contextual_ambiguity(roman : String) -> Bool {
  roman.length() > 0 && is_chromatic_roman(roman)
}

///|
fn chromatic_ambiguity_detail_for(key : Key) -> String {
  "chromatic harmony does not map to a stable function in \{key.to_string()}"
}

///|
fn trailing_cadence_context(analysis : HarmonyAnalysis) -> (CadenceKind, Int) {
  let len = analysis.functions.length()
  if len < 2 {
    return (Undetermined, -1)
  }

  let i = len - 2
  if analysis.functions[i] == Ambiguous ||
    analysis.functions[i + 1] == Ambiguous {
    return (Undetermined, -1)
  }

  let kind = detect_cadence_kind(analysis.romans[i], analysis.romans[i + 1])
  if kind == Undetermined {
    (Undetermined, -1)
  } else {
    (kind, i + 1)
  }
}

///|
pub fn analyze_harmony(key : Key, symbols : Array[String]) -> HarmonyAnalysis {
  let romans : Array[String] = []
  let functions : Array[HarmonyFunction] = []
  let findings : Array[HarmonyFinding] = []

  for i, symbol in symbols {
    match key.analyze_chord(symbol) {
      Ok(roman) => {
        let function = to_harmony_function(roman)
        romans.push(roman)
        functions.push(function)

        if function == Ambiguous {
          let detail = if is_contextual_ambiguity(roman) {
            chromatic_ambiguity_detail_for(key)
          } else {
            ambiguity_detail_for(key)
          }
          findings.push({ index: i, symbol, kind: Ambiguity, detail })
        }
      }
      Err(err) => {
        romans.push("")
        functions.push(Ambiguous)
        findings.push({ index: i, symbol, kind: InvalidInput, detail: err })
      }
    }
  }

  {
    key,
    symbols: symbols.map(fn(symbol) { symbol }),
    romans,
    functions,
    findings,
  }
}

///|
pub fn classify_cadence_context(analysis : HarmonyAnalysis) -> CadenceKind {
  trailing_cadence_context(analysis).0
}

///|
pub fn cadence_context_index(analysis : HarmonyAnalysis) -> Int {
  trailing_cadence_context(analysis).1
}
