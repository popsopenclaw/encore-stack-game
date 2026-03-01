#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "== backend build =="
dotnet build backend/Encore.Api/Encore.Api.csproj

echo "== backend tests =="
dotnet test backend/Encore.Api.Tests/Encore.Api.Tests.csproj

echo "== frontend analyze =="
(
  cd frontend
  flutter analyze
)

echo "== compose validation =="
docker compose config >/dev/null

echo "✅ local ci checks passed"
