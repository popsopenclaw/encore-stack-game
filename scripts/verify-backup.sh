#!/usr/bin/env bash
set -euo pipefail

# Verify backup artifacts created by scripts/backup-vm.sh
# Usage: ./scripts/verify-backup.sh ./backups/20260304-120000

DIR="${1:-}"
if [[ -z "$DIR" ]]; then
  echo "Usage: $0 <backup-dir>"
  exit 1
fi

if [[ ! -d "$DIR" ]]; then
  echo "Backup dir not found: $DIR" >&2
  exit 1
fi

SQL="$DIR/postgres.sql"
RDB="$DIR/valkey-dump.rdb"

echo "== verify postgres.sql =="
if [[ ! -f "$SQL" ]]; then
  echo "Missing postgres.sql" >&2
  exit 1
fi
if [[ ! -s "$SQL" ]]; then
  echo "postgres.sql is empty" >&2
  exit 1
fi

grep -qE "^--|CREATE TABLE|INSERT INTO" "$SQL" || {
  echo "postgres.sql does not look like a valid pg_dump" >&2
  exit 1
}

echo "== verify valkey dump =="
if [[ -f "$RDB" ]]; then
  # RDB header starts with REDIS
  sig=$(head -c 5 "$RDB" || true)
  if [[ "$sig" != "REDIS" ]]; then
    echo "valkey-dump.rdb has invalid header signature" >&2
    exit 1
  fi
  echo "valkey dump signature ok"
else
  echo "warning: valkey-dump.rdb not present (allowed if valkey backup copy was unavailable)"
fi

echo "✅ backup verification passed: $DIR"
