#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/deploy-vm.sh user@host [/opt/encore-stack-game] [main]
#
# Optional env vars:
#   SSH_PORT=22
#   SSH_KEY=~/.ssh/id_ed25519
#   ENV_FILE=.env.production

TARGET="${1:-}"
REMOTE_DIR="${2:-/opt/encore-stack-game}"
BRANCH="${3:-main}"
SSH_PORT="${SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"
ENV_FILE="${ENV_FILE:-.env}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 user@host [/remote/path] [branch]"
  exit 1
fi

SSH_OPTS=("-p" "$SSH_PORT" "-o" "StrictHostKeyChecking=accept-new")
if [[ -n "$SSH_KEY" ]]; then
  SSH_OPTS+=("-i" "$SSH_KEY")
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE"
  echo "Create it first (copy from .env.example)."
  exit 1
fi

echo "==> Ensuring remote directory exists"
ssh "${SSH_OPTS[@]}" "$TARGET" "mkdir -p '$REMOTE_DIR'"

echo "==> Syncing project files"
rsync -az --delete \
  --exclude '.git' \
  --exclude 'frontend/.dart_tool' \
  --exclude 'frontend/build' \
  --exclude '**/bin' \
  --exclude '**/obj' \
  -e "ssh -p $SSH_PORT ${SSH_KEY:+-i $SSH_KEY}" \
  ./ "$TARGET:$REMOTE_DIR/"

echo "==> Uploading env file"
scp "${SSH_OPTS[@]}" "$ENV_FILE" "$TARGET:$REMOTE_DIR/.env"

echo "==> Deploying with docker compose"
ssh "${SSH_OPTS[@]}" "$TARGET" "cd '$REMOTE_DIR' && docker compose pull && docker compose up -d --build && docker compose ps"

echo "✅ Deploy complete: $TARGET:$REMOTE_DIR"