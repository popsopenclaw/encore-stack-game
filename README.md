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

Backend API:
- `http://localhost:8080`
- Swagger: `http://localhost:8080/swagger`

## 3) Run Flutter app

```bash
cd frontend
flutter pub get
flutter run -d linux   # or windows/macos/android/ios
```

## API endpoints

- `GET /api/auth/github/url` -> returns GitHub authorize URL
- `POST /api/auth/github/exchange` -> exchanges OAuth code for JWT + user
- `POST /api/gamesessions` (Bearer JWT) -> create game session in Valkey
- `GET /api/gamesessions/{id}` (Bearer JWT) -> load session from Valkey
- `PUT /api/gamesessions/{id}/state` (Bearer JWT) -> update session state JSON

## Notes

- This scaffold targets mobile + native desktop only (no web build requested).
- EF Core uses `EnsureCreated` for fast bootstrap (replace with migrations for production).
- Session values in Valkey expire after 7 days by default.
