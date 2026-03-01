#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "== backend build =="
dotnet build backend/Encore.sln

echo "== backend tests (unit + integration) =="
dotnet test backend/Encore.sln --no-build

echo "== frontend analyze =="
(
  cd frontend
  flutter analyze
)

echo "== compose validation =="
docker compose config >/dev/null

echo "✅ local ci checks passed"
