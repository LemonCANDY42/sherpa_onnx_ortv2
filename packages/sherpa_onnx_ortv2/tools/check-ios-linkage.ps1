param(
  [string]$IosRoot = "../sherpa_onnx_ortv2_ios/ios",
  [string]$FrameworkName = "sherpa_onnx.xcframework"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $IosRoot)) {
  throw "iOS package root not found: $IosRoot"
}

$frameworkRoot = Join-Path $IosRoot $FrameworkName
if (-not (Test-Path $frameworkRoot)) {
  throw "Expected framework not found: $frameworkRoot"
}

# Guardrail: the iOS plugin should not ship a second ORT framework.
$bundledOrtArtifacts = Get-ChildItem -Path $IosRoot -Recurse -File | Where-Object {
  $_.Name -match "onnxruntime" -or $_.FullName -match "onnxruntime"
}

if ($bundledOrtArtifacts) {
  Write-Host "Unexpected onnxruntime artifacts found in iOS plugin:"
  $bundledOrtArtifacts | ForEach-Object { Write-Host " - $($_.FullName)" }
  throw "iOS linkage guard failed: bundled onnxruntime artifacts are not allowed."
}

# On macOS runners, also validate dynamic linkage if `otool` exists.
$otool = Get-Command otool -ErrorAction SilentlyContinue
if ($otool) {
  $binaries = Get-ChildItem -Path $frameworkRoot -Recurse -File | Where-Object {
    $_.Extension -eq "" -or $_.Name -eq "sherpa_onnx"
  }
  foreach ($bin in $binaries) {
    $otoolOutput = & otool -L $bin.FullName 2>$null
    if ($LASTEXITCODE -ne 0) {
      continue
    }
    if ($otoolOutput -match "onnxruntime") {
      throw "Unexpected dynamic dependency on onnxruntime in: $($bin.FullName)"
    }
  }
}

Write-Host "iOS linkage guard passed: no bundled onnxruntime artifacts."
