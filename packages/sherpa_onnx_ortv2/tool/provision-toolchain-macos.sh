#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script only supports macOS hosts." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required on macOS. Install brew first." >&2
  exit 1
fi

brew update
brew install wget cmake ninja gnu-sed || true

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode command line tools are required. Run: xcode-select --install" >&2
  exit 1
fi

echo "macOS native toolchain provision complete."
