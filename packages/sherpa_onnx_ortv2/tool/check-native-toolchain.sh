#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-all}"
MISS=()

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    MISS+=("$cmd")
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

check_android() {
  need_cmd git
  need_cmd bash
  need_cmd python3
  need_cmd sed
  need_cmd wget
  need_cmd unzip
  need_cmd cmake
  need_cmd make

  if ! resolve_android_ndk >/dev/null; then
    MISS+=("ANDROID_NDK (or ANDROID_NDK_ROOT / ANDROID_SDK_ROOT with installed ndk)")
  fi
}

check_ios() {
  need_cmd git
  need_cmd bash
  need_cmd python3
  need_cmd cmake
  need_cmd xcodebuild
  need_cmd lipo
  need_cmd install_name_tool
  need_cmd tar
  need_cmd wget
}

case "$TARGET" in
  android)
    check_android
    ;;
  ios)
    check_ios
    ;;
  all)
    check_android
    check_ios
    ;;
  *)
    echo "Usage: $0 [android|ios|all]" >&2
    exit 2
    ;;
esac

if [[ ${#MISS[@]} -gt 0 ]]; then
  echo "Missing toolchain dependencies for target '$TARGET':"
  for item in "${MISS[@]}"; do
    echo "  - $item"
  done
  exit 1
fi

echo "Native toolchain check passed for target '$TARGET'"
