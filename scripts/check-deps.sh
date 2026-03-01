#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/.dotnet/tools:$PATH"
export DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
export DOTNET_ROLL_FORWARD=Major

cd "$ROOT_DIR"

echo "== Backend outdated packages =="
(
  cd backend/Encore.Api
  dotnet list package --outdated || true
)

echo "== Frontend outdated packages =="
(
  cd frontend
  flutter pub outdated || true
)
