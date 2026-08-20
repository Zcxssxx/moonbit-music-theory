///|
pub(all) struct ProgressionScore {
  total : Int
  explanation : String
  findings : Array[HarmonyFinding]
} derive(Eq, Debug)

///|
fn cadence_score(kind : CadenceKind) -> Int {
  match kind {
    Authentic => 6
    Plagal => 4
    Deceptive => 2
    Half => 1
    Undetermined => 0
  }
}

///|
fn cadence_detail(kind : CadenceKind) -> String {
  match kind {
    Authentic => "dominant resolves to tonic"
    Plagal => "predominant resolves directly to tonic"
    Deceptive => "dominant avoids tonic resolution"
    Half => "phrase closes on the dominant"
    Undetermined => ""
  }
}

///|
fn cadence_explanation(kind : CadenceKind) -> String {
  match kind {
    Authentic => "authentic cadence +6"
    Plagal => "plagal cadence +4"
    Deceptive => "deceptive cadence +2"
    Half => "half cadence +1"
    Undetermined => ""
  }
}

///|
fn insert_finding_sorted(
  findings : Array[HarmonyFinding],
  finding : HarmonyFinding,
) -> Unit {
  findings.push(finding)
  let mut idx = findings.length() - 1
  while idx > 0 && findings[idx - 1].index > findings[idx].index {
    let prev = findings[idx - 1]
    findings[idx - 1] = findings[idx]
    findings[idx] = prev
    idx = idx - 1
  }
}

///|
pub fn score_progression_context(
  analysis : HarmonyAnalysis,
) -> ProgressionScore {
  let findings : Array[HarmonyFinding] = []
  let explanation_parts : Array[String] = []
  let mut total = 0

  let cadence = classify_cadence_context(analysis)
  let cadence_index = cadence_context_index(analysis)
  if cadence != Undetermined && cadence_index >= 0 {
    let symbol = analysis.symbols[cadence_index]
    insert_finding_sorted(findings, {
      index: cadence_index,
      symbol,
      kind: Cadence(cadence),
      detail: cadence_detail(cadence),
    })
    total = total + cadence_score(cadence)
    explanation_parts.push(cadence_explanation(cadence))
  }

  for finding in analysis.findings {
    insert_finding_sorted(findings, finding)
    match finding.kind {
      Ambiguity => {
        total = total - 1
        explanation_parts.push("ambiguous harmony -1")
      }
      InvalidInput => {
        total = total - 1
        explanation_parts.push("invalid input -1")
      }
      _ => ()
    }
  }

  let explanation = if explanation_parts.length() == 0 {
    "no strong cadence or ambiguity signals"
  } else {
    explanation_parts.join("; ")
  }

  { total, explanation, findings }
}
