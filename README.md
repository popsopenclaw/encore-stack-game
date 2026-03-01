# Encore Stack Game

Flutter frontend + .NET 8 backend using Docker Compose, Valkey for game sessions, and PostgreSQL for account data.

## Stack

- Frontend: Flutter (Android, iOS, Linux, macOS, Windows)
- Backend: ASP.NET Core Web API (.NET 8)
- Auth: GitHub OAuth App + JWT
- Session storage: Valkey
- Account storage: PostgreSQL
- Orchestration: Docker Compose

## 1) Configure env

```bash
cp .env.example .env
```

Fill GitHub OAuth credentials in `.env`.

### GitHub OAuth App settings

In GitHub OAuth App:
- Authorization callback URL: `http://localhost:5173/auth/callback` (or your desktop/mobile deep-link bridge)

## 2) Run backend + databases

```bash
docker compose up -d --build
```

Production-style run (no DB/cache public ports):

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

Backend API:
- `http://localhost:8080`
- Swagger: `http://localhost:8080/swagger`

## 3) Run Flutter app

```bash
cd frontend
flutter pub get
flutter run -d linux   # or windows/macos/android/ios
```

Set production default backend at build/run time (still overridable in-app):

```bash
flutter run -d linux --dart-define=BACKEND_URL=https://your-domain.com
```

## Quick launch script (frontend)

```bash
./scripts/run-frontend.sh
```

Optional device argument:

```bash
./scripts/run-frontend.sh linux
./scripts/run-frontend.sh windows
./scripts/run-frontend.sh macos
./scripts/run-frontend.sh android
./scripts/run-frontend.sh ios
```

Optional production backend default:

```bash
BACKEND_URL=https://your-domain.com ./scripts/run-frontend.sh linux
```

## Bootstrap a fresh Ubuntu server

Run on the Ubuntu VM:

```bash
sudo ./scripts/bootstrap-ubuntu.sh <vm-user>
```

This installs Docker + Compose plugin, rsync, ufw, fail2ban, enables Docker, and adds your user to the docker group.

## Deploy to Ubuntu VM (Docker)

Use the deploy script:

```bash
./scripts/deploy-vm.sh user@your-vm-ip /opt/encore-stack-game main
```

Optional env vars:

```bash
SSH_PORT=22 SSH_KEY=~/.ssh/id_ed25519 ENV_FILE=.env DEPLOY_MODE=prod ./scripts/deploy-vm.sh user@your-vm-ip
```

`DEPLOY_MODE=prod` uses `docker-compose.prod.yml` overlay (recommended for VM).

What it does:
- syncs project files to your VM via `rsync`
- uploads env file as `.env`
- runs `docker compose pull && docker compose up -d --build`

## API endpoints

Auth:
- `GET /api/auth/github/url` -> returns GitHub authorize URL
- `POST /api/auth/github/exchange` -> exchanges OAuth code for JWT + user

Gameplay (Bearer JWT):
- `POST /api/gameplay/start` -> start a new game state
- `GET /api/gameplay/{sessionId}` -> fetch game state
- `POST /api/gameplay/{sessionId}/roll` -> active player roll phase
- `POST /api/gameplay/{sessionId}/active-select` -> active picks dice (or pass)
- `GET /api/gameplay/{sessionId}/available-dice/{playerIndex}` -> dice available for that player this turn
- `POST /api/gameplay/{sessionId}/action` -> player submits move (or pass)
- `POST /api/gameplay/{sessionId}/encore` -> enables one extra round after end trigger
- `GET /api/gameplay/{sessionId}/score` -> score breakdown

Legacy session endpoints (still available):
- `POST /api/gamesessions`
- `GET /api/gamesessions/{id}`
- `PUT /api/gamesessions/{id}/state`

## DevOps helpers

- Local commands: `make up`, `make down`, `make test`, `make analyze`
- Local CI script: `./scripts/ci-local.sh`
- Rules audit matrix: `RULES_VALIDATION.md`
- API turn sequence: `TURN_FLOW.md`
- VM backup script (run on server): `./scripts/backup-vm.sh`

## Notes

- This scaffold targets mobile + native desktop only (no web build requested).
- EF Core uses `EnsureCreated` for fast bootstrap (replace with migrations for production).
- Session values in Valkey expire after 7 days by default.
