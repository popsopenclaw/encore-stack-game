#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/.dotnet/tools:$PATH"
export DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
export DOTNET_ROLL_FORWARD=Major

cd "$ROOT_DIR"

echo "== Ensure dotnet-outdated tool =="
if ! command -v dotnet-outdated >/dev/null 2>&1; then
  dotnet tool install -g dotnet-outdated-tool
else
  dotnet tool update -g dotnet-outdated-tool || true
fi

echo "== Backend: upgrade NuGet packages (within compatible target constraints) =="
(
  cd backend/Encore.Api
  dotnet restore
  dotnet-outdated -u || true
)

echo "== Frontend: attempt dependency upgrades =="
(
  cd frontend
  flutter pub upgrade --major-versions || true
)

echo "== Validate after upgrades =="
(
  cd "$ROOT_DIR"
  ./scripts/ci-local.sh
)

echo "✅ Dependency upgrade pass completed"
