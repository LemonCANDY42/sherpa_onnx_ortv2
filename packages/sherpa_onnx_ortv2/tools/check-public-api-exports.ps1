param(
  [Parameter(Mandatory = $true)]
  [string]$UpstreamVersion,
  [string]$ForkEntry = "lib/sherpa_onnx.dart",
  [string]$PubCacheRoot
)

$ErrorActionPreference = "Stop"

if (-not $PubCacheRoot) {
  if ($env:PUB_CACHE) {
    $PubCacheRoot = Join-Path $env:PUB_CACHE "hosted/pub.dev"
  } elseif ($env:LOCALAPPDATA) {
    $PubCacheRoot = Join-Path $env:LOCALAPPDATA "Pub/Cache/hosted/pub.dev"
  } else {
    $PubCacheRoot = Join-Path $HOME ".pub-cache/hosted/pub.dev"
  }
}

if (-not (Test-Path $ForkEntry)) {
  throw "Fork entry file not found: $ForkEntry"
}

$upstreamEntry = Join-Path $PubCacheRoot "sherpa_onnx-$UpstreamVersion/lib/sherpa_onnx.dart"
if (-not (Test-Path $upstreamEntry)) {
  throw "Upstream entry file not found: $upstreamEntry"
}

$forkExports = @((Get-Content $ForkEntry | Where-Object { $_ -match "^export 'src/.+\\.dart';$" }) `
  | ForEach-Object { $_.Trim() } `
  | Sort-Object -Unique)
$upstreamExports = @((Get-Content $upstreamEntry | Where-Object { $_ -match "^export 'src/.+\\.dart';$" }) `
  | ForEach-Object { $_.Trim() } `
  | Sort-Object -Unique)

$missing = Compare-Object -ReferenceObject $upstreamExports -DifferenceObject $forkExports -PassThru `
  | Where-Object { $_ -in $upstreamExports }

if ($missing) {
  Write-Host "Missing exports relative to upstream:"
  $missing | ForEach-Object { Write-Host " - $_" }
  throw "Public API export surface regression detected."
}

Write-Host "Public API export check passed against upstream $UpstreamVersion"
