param(
  [Parameter(Mandatory = $true)]
  [string]$SherpaVersion,
  [string]$PackagesRoot = "../../packages"
)

$ErrorActionPreference = "Stop"

$pubRoot = if ($env:PUB_CACHE) {
  Join-Path $env:PUB_CACHE "hosted/pub.dev"
} elseif ($env:LOCALAPPDATA) {
  Join-Path $env:LOCALAPPDATA "Pub/Cache/hosted/pub.dev"
} else {
  Join-Path $HOME ".pub-cache/hosted/pub.dev"
}
$mainSource = Join-Path $pubRoot "sherpa_onnx-$SherpaVersion"
$androidSource = Join-Path $pubRoot "sherpa_onnx_android-$SherpaVersion"
$iosSource = Join-Path $pubRoot "sherpa_onnx_ios-$SherpaVersion"

if (-not (Test-Path $mainSource)) { throw "Missing upstream package: $mainSource" }
if (-not (Test-Path $androidSource)) { throw "Missing upstream package: $androidSource" }
if (-not (Test-Path $iosSource)) { throw "Missing upstream package: $iosSource" }

$mainDest = Join-Path $PackagesRoot "sherpa_onnx_ortv2"
$androidDest = Join-Path $PackagesRoot "sherpa_onnx_ortv2_android"
$iosDest = Join-Path $PackagesRoot "sherpa_onnx_ortv2_ios"

Write-Host "Syncing upstream sherpa_onnx $SherpaVersion ..."
Copy-Item -Recurse -Force $mainSource $mainDest
Copy-Item -Recurse -Force $androidSource $androidDest
Copy-Item -Recurse -Force $iosSource $iosDest

Write-Host "Done. Re-apply fork patches (pubspec rename, auto provider, CI guards)."
