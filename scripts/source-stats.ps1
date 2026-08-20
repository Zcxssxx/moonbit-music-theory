$root = Split-Path -Parent $PSScriptRoot
$files = Get-ChildItem (Join-Path $root "src") -Recurse -File -Filter "*.mbt"
$production = $files | Where-Object { $_.Name -notmatch "(_test|_wbtest)\.mbt$" }
$tests = $files | Where-Object { $_.Name -match "(_test|_wbtest)\.mbt$" }
function Lines($items) {
  if ($null -eq $items) { return 0 }
  return (($items | Get-Content | Measure-Object -Line).Lines)
}
[pscustomobject]@{
  production_files = @($production).Count
  production_lines = Lines $production
  test_files = @($tests).Count
  test_lines = Lines $tests
  total_moonbit_lines = Lines $files
}
