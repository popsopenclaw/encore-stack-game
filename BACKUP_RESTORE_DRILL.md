# BACKUP_RESTORE_DRILL

Use this drill periodically on your VM to ensure backup + restore paths are healthy.

## 1) Create backup

```bash
./scripts/backup-vm.sh
```

This creates a timestamped folder under `./backups/<timestamp>` with:
- `postgres.sql`
- `valkey-dump.rdb` (when available)

## 2) Verify backup integrity

```bash
./scripts/verify-backup.sh ./backups/<timestamp>
```

Checks performed:
- `postgres.sql` exists, is non-empty, and has SQL/pg_dump-like content
- `valkey-dump.rdb` signature starts with `REDIS` (if present)

## 3) Restore drill (staging/non-prod)

### Postgres restore

```bash
# inside project directory on restore target
docker compose up -d postgres
cat ./backups/<timestamp>/postgres.sql | docker exec -i encore-postgres psql -U encore -d encore_game
```

### Valkey restore

```bash
docker compose up -d valkey
# stop valkey, replace dump, restart
docker compose stop valkey
docker cp ./backups/<timestamp>/valkey-dump.rdb encore-valkey:/data/dump.rdb
docker compose start valkey
```

## 4) Validate app behavior

```bash
./scripts/smoke-local.sh
```

## Frequency

- Recommended: weekly for backup creation + verification
- Recommended: monthly full restore drill on staging
