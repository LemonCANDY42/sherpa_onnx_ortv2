param(
  [Parameter(Mandatory = $true)]
  [string]$SherpaTag,
  [Parameter(Mandatory = $true)]
  [string]$OrtVersion,
  [string]$FlutterMin = "3.0.0",
  [string]$AndroidNdk = "29.0.14206865",
  [string]$IosDeploymentTarget = "13.0",
  [string]$MatrixPath = "compat-matrix.yaml"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $MatrixPath)) {
  throw "compat matrix not found: $MatrixPath"
}

$content = Get-Content $MatrixPath -Raw
$escapedSherpa = [Regex]::Escape($SherpaTag)
$escapedOrt = [Regex]::Escape($OrtVersion)
$existsPattern = "(?ms)-\s+sherpa_tag:\s*`"$escapedSherpa`"\s+ort_version:\s*`"$escapedOrt`""
if ([Regex]::IsMatch($content, $existsPattern)) {
  Write-Host "Compat entry already exists for sherpa_tag=$SherpaTag ort_version=$OrtVersion"
  exit 0
}

$newEntry = @"
  - sherpa_tag: "$SherpaTag"
    ort_version: "$OrtVersion"
    flutter_min: "$FlutterMin"
    android_ndk: "$AndroidNdk"
    ios_deployment_target: "$IosDeploymentTarget"
    status: "planned"
    notes: "Auto-added by upstream sync workflow."
"@

if ($content.TrimEnd().EndsWith("entries:")) {
  $updated = $content.TrimEnd() + "`r`n" + $newEntry + "`r`n"
} else {
  $updated = $content.TrimEnd() + "`r`n" + $newEntry + "`r`n"
}
Set-Content $MatrixPath $updated
Write-Host "Added compat entry for sherpa_tag=$SherpaTag ort_version=$OrtVersion"
