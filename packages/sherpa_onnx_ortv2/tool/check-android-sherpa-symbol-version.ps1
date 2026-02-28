param(
  [string]$JniRoot = "../sherpa_onnx_ortv2_android/android/src/main/jniLibs",
  [string]$ExpectedOrtVersion = "1.23.2"
)

$ErrorActionPreference = "Stop"

$abis = @("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
$token = "VERS_$ExpectedOrtVersion"
$legacyToken = "VERS_1.17.1"

foreach ($abi in $abis) {
  $libPath = Join-Path $JniRoot "$abi/libsherpa-onnx-c-api.so"
  if (-not (Test-Path $libPath)) {
    throw "Missing libsherpa-onnx-c-api.so for ABI: $abi"
  }

  $bytes = [System.IO.File]::ReadAllBytes($libPath)
  $content = [System.Text.Encoding]::ASCII.GetString($bytes)

  if ($content -notmatch [Regex]::Escape($token)) {
    throw "ABI $abi does not contain expected symbol version token: $token"
  }

  if ($ExpectedOrtVersion -ne "1.17.1" -and $content -match [Regex]::Escape($legacyToken)) {
    throw "ABI $abi still contains legacy symbol version token: $legacyToken"
  }
}

Write-Host "Android sherpa symbol version check passed for $ExpectedOrtVersion"
