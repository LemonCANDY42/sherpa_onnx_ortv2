param(
  [Parameter(Mandatory = $true)]
  [string]$SearchRoot,
  [Parameter(Mandatory = $true)]
  [string]$ExpectedVersionToken
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SearchRoot)) {
  throw "Search root not found: $SearchRoot"
}

$libs = Get-ChildItem -Path $SearchRoot -Recurse -Filter "libonnxruntime.so" -File
if (-not $libs) {
  throw "No libonnxruntime.so found under: $SearchRoot"
}

if ($libs.Count -gt 1) {
  Write-Host "Found multiple libonnxruntime.so files:"
  $libs | ForEach-Object { Write-Host " - $($_.FullName)" }
  throw "Expected exactly one libonnxruntime.so in release artifact"
}

$target = $libs[0].FullName
$bytes = [System.IO.File]::ReadAllBytes($target)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)

if (-not $text.Contains($ExpectedVersionToken)) {
  throw "libonnxruntime.so version token mismatch. Expected token '$ExpectedVersionToken' in $target"
}

Write-Host "Android ONNX Runtime check passed: $target contains $ExpectedVersionToken"
