#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"

DEVICE="${1:-linux}"

cd "$FRONTEND_DIR"
flutter pub get
flutter run -d "$DEVICE"
