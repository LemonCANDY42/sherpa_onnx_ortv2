param(
  [Parameter(Mandatory = $true)]
  [string]$SherpaTag,
  [Parameter(Mandatory = $true)]
  [string]$OrtVersion,
  [string]$MatrixPath = "compat-matrix.yaml"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $MatrixPath)) {
  throw "compat matrix not found: $MatrixPath"
}

$content = Get-Content $MatrixPath -Raw

$escapedSherpa = [Regex]::Escape($SherpaTag)
$escapedOrt = [Regex]::Escape($OrtVersion)
$pattern = "(?ms)-\s+sherpa_tag:\s*`"$escapedSherpa`"\s+ort_version:\s*`"$escapedOrt`".*?status:\s*`"(?<status>[^`"]+)`""
$match = [Regex]::Match($content, $pattern)

if (-not $match.Success) {
  throw "No compat entry for sherpa_tag=$SherpaTag ort_version=$OrtVersion"
}

$status = $match.Groups["status"].Value.ToLowerInvariant()
if ($status -in @("blocked", "paused")) {
  throw "Compat entry is not releasable. status=$status"
}

Write-Host "Compat matrix check passed: sherpa_tag=$SherpaTag ort_version=$OrtVersion status=$status"
