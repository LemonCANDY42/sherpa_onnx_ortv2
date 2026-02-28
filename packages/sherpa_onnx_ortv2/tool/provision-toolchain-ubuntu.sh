#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script only supports Linux hosts." >&2
  exit 1
fi

PKGS=(
  build-essential
  cmake
  ninja-build
  wget
  unzip
  git
  python3
)

if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

${SUDO} apt-get update
${SUDO} apt-get install -y "${PKGS[@]}"

echo "Ubuntu native toolchain provision complete."
