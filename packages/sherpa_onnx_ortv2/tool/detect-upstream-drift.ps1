param(
  [string]$CompatMatrixPath = "compat-matrix.yaml",
  [switch]$FailOnDrift
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CompatMatrixPath)) {
  throw "compat matrix not found: $CompatMatrixPath"
}

$matrixContent = Get-Content $CompatMatrixPath -Raw

$entries = [Regex]::Matches(
  $matrixContent,
  '(?ms)-\s+sherpa_tag:\s*"(?<sherpa>[^"]+)"\s+ort_version:\s*"(?<ort>[^"]+)"\s+.*?status:\s*"(?<status>[^"]+)"'
)

if ($entries.Count -eq 0) {
  throw "No entries parsed from compat matrix: $CompatMatrixPath"
}

$latestMatrixSherpa = ($entries | ForEach-Object { [Version]$_.Groups['sherpa'].Value } | Sort-Object -Descending | Select-Object -First 1).ToString()
$latestMatrixOrt = ($entries | ForEach-Object { [Version]$_.Groups['ort'].Value } | Sort-Object -Descending | Select-Object -First 1).ToString()

$sherpaPub = Invoke-RestMethod -Uri 'https://pub.dev/api/packages/sherpa_onnx' -Method Get
$ortPub = Invoke-RestMethod -Uri 'https://pub.dev/api/packages/onnxruntime_v2' -Method Get

$latestSherpa = $sherpaPub.latest.version
$latestOrtWithBuild = $ortPub.latest.version
$latestOrt = ($latestOrtWithBuild -split '\+')[0]

$driftMessages = @()
if ([Version]$latestSherpa -gt [Version]$latestMatrixSherpa) {
  $driftMessages += "sherpa_onnx drift: pub=$latestSherpa matrix=$latestMatrixSherpa"
}
if ([Version]$latestOrt -gt [Version]$latestMatrixOrt) {
  $driftMessages += "onnxruntime_v2 drift: pub=$latestOrtWithBuild matrix=$latestMatrixOrt"
}

Write-Host "Latest pub.dev sherpa_onnx: $latestSherpa"
Write-Host "Latest pub.dev onnxruntime_v2: $latestOrtWithBuild"
Write-Host "Matrix latest sherpa_tag: $latestMatrixSherpa"
Write-Host "Matrix latest ort_version: $latestMatrixOrt"

if ($driftMessages.Count -gt 0) {
  $driftMessages | ForEach-Object { Write-Host "DRIFT: $_" }
  if ($FailOnDrift) {
    throw "Upstream drift detected."
  }
} else {
  Write-Host "No upstream drift detected."
}
