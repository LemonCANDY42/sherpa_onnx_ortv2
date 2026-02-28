#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  cat <<'EOF'
Usage:
  rebuild-ios-native.sh <sherpa_tag> <ort_version> <repo_root> [work_dir]

Example:
  rebuild-ios-native.sh v1.12.27 1.23.2 "$PWD" "$PWD/.native-rebuild/ios"
EOF
  exit 1
fi

SHERPA_TAG_INPUT="$1"
ORT_VERSION="$2"
REPO_ROOT="$(cd "$3" && pwd)"
WORK_DIR="${4:-$REPO_ROOT/.native-rebuild/ios}"

normalize_tag() {
  local raw="$1"
  if [[ "$raw" == v* ]]; then
    echo "$raw"
  else
    echo "v$raw"
  fi
}

patch_ort_version_hook() {
  local file="$1"
  python - "$file" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
updated = re.sub(
    r"^onnxruntime_version=1\.17\.1$",
    "onnxruntime_version=${SHERPA_ONNXRUNTIME_VERSION:-1.17.1}",
    text,
    flags=re.MULTILINE,
)
if updated == text:
    raise SystemExit(f"Failed to patch ORT version hook in {path}")
path.write_text(updated, encoding="utf-8")
PY
}

SHERPA_TAG="$(normalize_tag "$SHERPA_TAG_INPUT")"

export SHERPA_ONNXRUNTIME_VERSION="$ORT_VERSION"
export SHERPA_ONNX_ENABLE_JNI=OFF
export SHERPA_ONNX_ENABLE_C_API=ON
export SHERPA_ONNX_ENABLE_BINARY=OFF
export SHERPA_ONNX_ENABLE_TTS=ON
export SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION=ON

SRC_DIR="$WORK_DIR/sherpa-onnx"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "[ios-rebuild] cloning sherpa-onnx $SHERPA_TAG"
git clone --depth 1 --branch "$SHERPA_TAG" --recursive \
  https://github.com/k2-fsa/sherpa-onnx.git "$SRC_DIR"

pushd "$SRC_DIR" >/dev/null
patch_ort_version_hook "build-ios-shared.sh"

echo "[ios-rebuild] building xcframework with ORT $ORT_VERSION"
bash ./build-ios-shared.sh

SRC_XC="$SRC_DIR/build-ios-shared/sherpa_onnx.xcframework"
DEST_XC="$REPO_ROOT/packages/sherpa_onnx_ortv2_ios/ios/sherpa_onnx.xcframework"

if [[ ! -d "$SRC_XC" ]]; then
  echo "ERROR: missing xcframework output at $SRC_XC" >&2
  exit 1
fi

rm -rf "$DEST_XC"
cp -R "$SRC_XC" "$DEST_XC"

if [[ ! -f "$DEST_XC/ios-arm64/sherpa_onnx.framework/sherpa_onnx" ]]; then
  echo "ERROR: invalid iOS xcframework output" >&2
  exit 1
fi

popd >/dev/null

echo "[ios-rebuild] done"
