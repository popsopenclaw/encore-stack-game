#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "== smoke: compose up =="
docker compose up -d --build

echo "== smoke: wait for api health =="
for i in {1..30}; do
  if curl -fsS http://localhost:8080/health >/dev/null 2>&1; then
    echo "api healthy"
    break
  fi
  sleep 2
  if [[ "$i" -eq 30 ]]; then
    echo "api did not become healthy in time" >&2
    exit 1
  fi
done

echo "== smoke: public endpoint =="
python3 - << 'PY'
import json, urllib.request
payload = urllib.request.urlopen('http://localhost:8080/api/auth/github/url?state=smoke', timeout=10).read().decode()
obj = json.loads(payload)
assert 'url' in obj and obj['url'], 'missing url in auth payload'
print('auth url ok')
PY

echo "== smoke: protected endpoint should be unauthorized without token =="
code=$(curl -s -o /tmp/smoke_gameplay.txt -w "%{http_code}" http://localhost:8080/api/gameplay/test-session)
if [[ "$code" != "401" ]]; then
  echo "expected 401 on protected endpoint, got $code" >&2
  cat /tmp/smoke_gameplay.txt >&2 || true
  exit 1
fi

echo "== smoke: local ci checks =="
./scripts/ci-local.sh

echo "✅ smoke-local passed"
