#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  cat <<'EOF'
Usage:
  rebuild-android-native.sh <sherpa_tag> <ort_version> <repo_root> [work_dir]

Example:
  rebuild-android-native.sh v1.12.27 1.23.2 "$PWD" "$PWD/.native-rebuild/android"
EOF
  exit 1
fi

SHERPA_TAG_INPUT="$1"
ORT_VERSION="$2"
REPO_ROOT="$(cd "$3" && pwd)"
WORK_DIR="${4:-$REPO_ROOT/.native-rebuild/android}"

normalize_tag() {
  local raw="$1"
  if [[ "$raw" == v* ]]; then
    echo "$raw"
  else
    echo "v$raw"
  fi
}

resolve_android_ndk() {
  if [[ -n "${ANDROID_NDK:-}" && -d "${ANDROID_NDK}" ]]; then
    echo "${ANDROID_NDK}"
    return 0
  fi

  if [[ -n "${ANDROID_NDK_ROOT:-}" && -d "${ANDROID_NDK_ROOT}" ]]; then
    echo "${ANDROID_NDK_ROOT}"
    return 0
  fi

  local sdk_candidates=()
  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    sdk_candidates+=("${ANDROID_SDK_ROOT}")
  fi
  if [[ -n "${ANDROID_HOME:-}" ]]; then
    sdk_candidates+=("${ANDROID_HOME}")
  fi
  sdk_candidates+=("$HOME/Android/Sdk")

  for sdk in "${sdk_candidates[@]}"; do
    if [[ -d "$sdk/ndk" ]]; then
      local latest
      latest="$(ls -1 "$sdk/ndk" | sort -V | tail -n 1 || true)"
      if [[ -n "$latest" && -d "$sdk/ndk/$latest" ]]; then
        echo "$sdk/ndk/$latest"
        return 0
      fi
    fi
  done

  return 1
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
ANDROID_NDK_PATH="$(resolve_android_ndk || true)"
if [[ -z "$ANDROID_NDK_PATH" || ! -d "$ANDROID_NDK_PATH" ]]; then
  echo "ERROR: Android NDK not found. Set ANDROID_NDK or ANDROID_NDK_ROOT." >&2
  exit 1
fi

export ANDROID_NDK="$ANDROID_NDK_PATH"
export SHERPA_ONNXRUNTIME_VERSION="$ORT_VERSION"
export SHERPA_ONNX_ENABLE_JNI=OFF
export SHERPA_ONNX_ENABLE_C_API=ON
export SHERPA_ONNX_ENABLE_BINARY=OFF
export SHERPA_ONNX_ENABLE_TTS=ON
export SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION=ON
export SHERPA_ONNX_ENABLE_RKNN=OFF
export SHERPA_ONNX_ENABLE_QNN=OFF
export SHERPA_ONNX_ANDROID_PLATFORM=android-21
export BUILD_SHARED_LIBS=ON

SRC_DIR="$WORK_DIR/sherpa-onnx"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

echo "[android-rebuild] cloning sherpa-onnx $SHERPA_TAG"
git clone --depth 1 --branch "$SHERPA_TAG" --recursive \
  https://github.com/k2-fsa/sherpa-onnx.git "$SRC_DIR"

pushd "$SRC_DIR" >/dev/null

for build_script in \
  build-android-arm64-v8a.sh \
  build-android-armv7-eabi.sh \
  build-android-x86.sh \
  build-android-x86-64.sh; do
  patch_ort_version_hook "$build_script"
done

declare -A script_to_abi=(
  ["build-android-arm64-v8a.sh"]="arm64-v8a"
  ["build-android-armv7-eabi.sh"]="armeabi-v7a"
  ["build-android-x86.sh"]="x86"
  ["build-android-x86-64.sh"]="x86_64"
)

for script in \
  build-android-arm64-v8a.sh \
  build-android-armv7-eabi.sh \
  build-android-x86.sh \
  build-android-x86-64.sh; do
  echo "[android-rebuild] building ${script_to_abi[$script]} with ORT $ORT_VERSION"
  bash "./$script"
done

DEST_JNI="$REPO_ROOT/packages/sherpa_onnx_ortv2_android/android/src/main/jniLibs"

declare -A abi_to_build_dir=(
  ["arm64-v8a"]="build-android-arm64-v8a"
  ["armeabi-v7a"]="build-android-armv7-eabi"
  ["x86"]="build-android-x86"
  ["x86_64"]="build-android-x86-64"
)

for abi in arm64-v8a armeabi-v7a x86 x86_64; do
  src_base="${abi_to_build_dir[$abi]}/install/lib"
  src_c_api="$src_base/libsherpa-onnx-c-api.so"
  src_cxx_api="$src_base/libsherpa-onnx-cxx-api.so"
  dst_dir="$DEST_JNI/$abi"

  if [[ ! -f "$src_c_api" || ! -f "$src_cxx_api" ]]; then
    echo "ERROR: missing build output for ABI $abi" >&2
    exit 1
  fi

  mkdir -p "$dst_dir"
  cp -f "$src_c_api" "$dst_dir/libsherpa-onnx-c-api.so"
  cp -f "$src_cxx_api" "$dst_dir/libsherpa-onnx-cxx-api.so"

  if ! strings "$dst_dir/libsherpa-onnx-c-api.so" | grep -q "VERS_${ORT_VERSION}"; then
    echo "ERROR: ABI $abi libsherpa-onnx-c-api.so is not linked against VERS_${ORT_VERSION}" >&2
    exit 1
  fi
done

popd >/dev/null

echo "[android-rebuild] done"
