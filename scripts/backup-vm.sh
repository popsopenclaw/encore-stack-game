#!/usr/bin/env bash
set -euo pipefail

# Run on VM inside project directory (where docker-compose.yml lives)
# Creates timestamped postgres dump + valkey snapshot in ./backups

TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${1:-./backups/$TS}"
mkdir -p "$OUT_DIR"

POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-encore-postgres}"
VALKEY_CONTAINER="${VALKEY_CONTAINER:-encore-valkey}"
POSTGRES_DB="${POSTGRES_DB:-encore_game}"
POSTGRES_USER="${POSTGRES_USER:-encore}"

echo "==> Backing up postgres"
docker exec "$POSTGRES_CONTAINER" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "$OUT_DIR/postgres.sql"

echo "==> Backing up valkey"
docker exec "$VALKEY_CONTAINER" valkey-cli SAVE >/dev/null
# default rdb path on official image
if docker cp "$VALKEY_CONTAINER":/data/dump.rdb "$OUT_DIR/valkey-dump.rdb" 2>/dev/null; then
  echo "valkey dump copied"
else
  echo "warning: could not copy /data/dump.rdb"
fi

echo "✅ Backup complete at $OUT_DIR"
