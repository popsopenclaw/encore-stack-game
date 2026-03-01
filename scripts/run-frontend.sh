#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"

DEVICE="${1:-linux}"
BACKEND_URL="${BACKEND_URL:-}"

cd "$FRONTEND_DIR"
flutter pub get

if [[ -n "$BACKEND_URL" ]]; then
  flutter run -d "$DEVICE" --dart-define=BACKEND_URL="$BACKEND_URL"
else
  flutter run -d "$DEVICE"
fi
