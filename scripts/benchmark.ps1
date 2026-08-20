$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
$artifact = Join-Path $root "artifacts\benchmark\latest.txt"
$artifactDir = Split-Path -Parent $artifact
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("MoonBit music-theory native benchmark")
$lines.Add("target: native release")
$lines.Add("fixture: four-chord report + voice-leading + SMF round-trip")
$lines.Add((moon version --all 2>&1 | Out-String).Trim())
Push-Location $root
try {
  & moon run bench --target native --release -- 1000 *> $null
  if ($LASTEXITCODE -ne 0) { $lines.Add("warmup: failed (native toolchain unavailable)") } else { $lines.Add("warmup: passed") }
  $samples = @()
  for ($i = 1; $i -le 5; $i++) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & moon run bench --target native --release -- 1000 *> $null
    $sw.Stop()
    if ($LASTEXITCODE -eq 0) {
      $ms = [math]::Round($sw.Elapsed.TotalMilliseconds, 3)
      $samples += $ms
      $lines.Add("sample_$i`_ms: $ms")
    } else { $lines.Add("sample_$($i): failed (native toolchain unavailable)") }
  }
  if ($samples.Count -gt 0) {
    $sorted = $samples | Sort-Object
    $median = $sorted[[int][math]::Floor($sorted.Count / 2)]
    $lines.Add("min_ms: $($sorted[0])")
    $lines.Add("median_ms: $median")
    $lines.Add("max_ms: $($sorted[$sorted.Count - 1])")
  } else {
    $lines.Add("timing_samples: none")
    $lines.Add("note: no fabricated timings; inspect native toolchain error above")
  }
  $lines | Set-Content -LiteralPath $artifact -Encoding utf8
  $lines | ForEach-Object { Write-Output $_ }
} finally { Pop-Location }
