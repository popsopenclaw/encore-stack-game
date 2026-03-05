# CLAUDE.md -- Encore Stack Game

## Project Overview

Multiplayer board game (Encore / Noch Mal!) built with:
- **Frontend:** Flutter (Dart) -- desktop/web SPA
- **Backend:** ASP.NET Core (.NET 10) -- REST API + SignalR
- **Database:** PostgreSQL 16 (via EF Core)
- **Cache:** Valkey 7.2 (Redis-compatible) -- game session state
- **Auth:** GitHub OAuth 2.0 + JWT Bearer tokens

## Quick Commands

```bash
make up              # docker compose up -d --build (postgres, valkey, migrate, backend)
make down            # stop all containers
make test            # dotnet test backend unit tests
make build           # dotnet build backend
make analyze         # flutter analyze
make logs            # tail container logs

./scripts/ci-local.sh      # full local CI: build + test + analyze + compose config
./scripts/run-frontend.sh  # launch Flutter app (accepts BACKEND_URL env var)
./scripts/smoke-local.sh   # smoke test
./scripts/check-deps.sh    # dependency checker
```

Frontend dev:
```bash
cd frontend && flutter run -d linux    # or -d chrome
cd frontend && flutter test
```

## Backend Architecture (Clean Architecture -- 4 Layers)

```
Encore.Api                 -- Composition root, controllers, middleware, SignalR hubs
Encore.Application         -- Use cases, contracts/ports (interfaces)
Encore.Infrastructure      -- Adapters: EF Core, Valkey, OAuth, JWT
Encore.Domain              -- Pure business entities and models
Encore.Api.Tests           -- Unit tests (xUnit)
Encore.Api.IntegrationTests -- Integration tests with fakes
```

**Dependency rule:** Api -> Application -> Domain; Infrastructure -> Application. Never reference Infrastructure from Application.

### Key Backend Files

| Path | Purpose |
|------|---------|
| `backend/Encore.Api/Program.cs` | DI registration, middleware pipeline |
| `backend/Encore.Api/Middleware/ExceptionHandlingMiddleware.cs` | Global error mapping |
| `backend/Encore.Api/Controllers/GameplayController.cs` | Game endpoints |
| `backend/Encore.Api/Controllers/LobbyController.cs` | Lobby endpoints |
| `backend/Encore.Api/Hubs/LobbyHub.cs` | SignalR hub |
| `backend/Encore.Application/Gameplay/GameplayUseCase.cs` | Game orchestration |
| `backend/Encore.Application/Lobby/LobbyUseCase.cs` | Lobby orchestration |
| `backend/Encore.Infrastructure/Services/EncoreRulesEngine.cs` | All game rules |
| `backend/Encore.Infrastructure/Services/GameSessionService.cs` | Valkey session store |
| `backend/Encore.Infrastructure/Services/BoardTemplateProvider.cs` | Board layout from JSON |

### API Error Shape

All API errors return:
```json
{ "code": "not_found", "message": "...", "correlationId": "..." }
```

Exception-to-status mapping (ExceptionHandlingMiddleware):
| Exception | HTTP | Code |
|-----------|------|------|
| `KeyNotFoundException` | 404 | `not_found` |
| `UnauthorizedAccessException` | 403 | `forbidden` |
| `InvalidOperationException` | 400 | `invalid_operation` |
| `RedisConnectionException` | 503 | `redis_unavailable` |
| anything else | 500 | `internal_error` |

### Conventions

- **Valkey key pattern:** `game:{gameKey}:session:{sessionId}` (see `GameSessionService.Key()`)
- **SignalR group name:** `lobby:{code.Trim().ToUpperInvariant()}` (see `LobbyHub.GroupName()`)
- **JWT:** `sub` claim = account ID (Guid). Signing key from `Jwt:SigningKey` config.
- **Board cells:** IDs `c1`..`c{n}`, columns A through O, column H = mandatory start column

## Frontend Architecture

### Screens (`frontend/lib/screens/`)

| Route | Screen | Purpose |
|-------|--------|---------|
| `/` | SessionGateScreen | Auth gate (redirect to login or home) |
| `/login` | LoginScreen | GitHub OAuth flow |
| `/home` | HomeScreen | Dashboard / lobby list |
| `/lobby/create` | CreateLobbyScreen | Create new lobby |
| `/lobby/join` | JoinLobbyScreen | Join by code |
| `/lobby/room` | LobbyRoomScreen | Lobby waiting room |
| `/game` | GameScreen | Active game board |
| `/settings` | SettingsScreen | Backend URL config |
| `/profile` | ProfileScreen | Account info |

### State Management (`frontend/lib/state/`)

Global `ChangeNotifier` singletons, listened to via `AnimatedBuilder`:
- `authSessionController` -- JWT lifecycle (init/login/logout)
- `lobbyController` -- Lobby CRUD + SignalR realtime
- `gameController` -- Game state, dice, moves

### Services (`frontend/lib/services/`)

- **ApiClient** -- HTTP wrapper with JWT injection. Throws `ApiErrorException(statusCode, code, message, correlationId)` or `UnauthorizedApiException`.
- **LobbyRealtimeService** -- SignalR HubConnection to `/hubs/lobby`. Listens for `lobbyUpdated` events. Auto-reconnect with backoff.

### Theme System (`frontend/lib/theme/`)

- `AppPalette` -- All color constants. Use `AppPalette.fromGameColor(name)` for game colors.
- `AppSpacing` -- Named spacing: `xxs(4)`, `xs(6)`, `sm(8)`, `md(12)`, `lg(16)`, `xl(20)`
- `AppTextStyles` -- Predefined text styles (title, subtitle, body, boardLabel, etc.)
- `AppTokens` -- ThemeExtensions: `AppRadius` (card/panel/pill), `AppSurface` (boardLikePanel)

### SharedPreferences Keys

- `kBackendPrefKey` = `'backend_url'` (defined in `frontend/lib/config/backend_config.dart`)
- `kJwtPrefKey` = `'jwt_token'`

### Widgets (`frontend/lib/widgets/`)

- `AppPanel` -- Warm surface panel (uses `AppSurface.boardLikePanel`)
- `AppMetaPill` -- Small info pill badge
- `DieChip` -- Colored die display chip
- `CommonCard` -- Standard card wrapper
- `BoardSheet` -- Game board grid
- `MatchHudPanel` -- Match controls and dice HUD (extracted from GameScreen)
- `GameAuditPanel` -- Score/timeline display
- `AppShell` -- Scaffold with AppBar

## How To: Add a New Feature

### New Backend Feature

1. Define domain entity/value object in `Encore.Domain`
2. Define port interface in `Encore.Application/Contracts`
3. Implement adapter in `Encore.Infrastructure`
4. Create or extend use case in `Encore.Application`
5. Add controller endpoint in `Encore.Api/Controllers`
6. Register in DI in `Program.cs`
7. Add tests in `Encore.Api.Tests`

### New Frontend Screen

1. Create screen widget in `frontend/lib/screens/`
2. Add route in `frontend/lib/app/router.dart`
3. If needed, add state controller in `frontend/lib/state/`
4. Use `AppShell` for scaffold, `AppPanel`/`CommonCard` for containers
5. Use `AppPalette`, `AppSpacing`, `AppTextStyles` -- never hardcode colors or spacing

### New Game Rule

1. Modify `EncoreRulesEngine` in `Encore.Infrastructure/Services/`
2. Add unit tests in `Encore.Api.Tests/EncoreRulesEngineTests.cs`
3. Throw `InvalidOperationException` for rule violations (auto-mapped to 400)

## Testing Strategy

- **Backend unit tests:** `dotnet test backend/Encore.Api.Tests/` -- rules engine, use cases
- **Backend integration tests:** `dotnet test backend/Encore.Api.IntegrationTests/` -- API endpoints with fakes
- **Frontend analysis:** `flutter analyze` -- static analysis
- **Frontend tests:** `flutter test` -- widget/contract tests
- **CI:** GitHub Actions runs backend tests + Flutter analyze + Docker compose config on push/PR

## Style & Naming

- **Commits:** Conventional commits -- `feat(scope):`, `fix(scope):`, `style(scope):`, `refactor(scope):`, `docs:`, `test:`
- **C# naming:** PascalCase types/methods, camelCase locals, `_camelCase` private fields
- **Dart naming:** camelCase functions/variables, PascalCase types, `_prefix` for private
- **Frontend colors:** Always use `AppPalette` constants -- never hardcode `Color(0x...)` outside `app_palette.dart`
- **Frontend spacing:** Always use `AppSpacing` tokens -- never hardcode numeric spacing values
- **API routes:** kebab-case paths, e.g. `/api/gameplay/{sessionId}/active-select`
