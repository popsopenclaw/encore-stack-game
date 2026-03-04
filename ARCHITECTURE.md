# ARCHITECTURE

## Backend layers

- **Encore.Domain**
  - Pure domain models and game state/rules data structures.
  - No infrastructure/framework dependencies.

- **Encore.Application**
  - Use cases + contracts + ports (abstractions).
  - Depends on Domain, never on API or concrete infra classes.

- **Encore.Infrastructure**
  - Implements Application ports with concrete technologies:
    - EF Core/Postgres
    - Redis/Valkey
    - OAuth/JWT adapters
  - Depends on Domain + Application.

- **Encore.Api**
  - HTTP controllers, SignalR hubs, composition root (DI wiring).
  - Depends on Application and Infrastructure registrations.

## Dependency rule

Allowed direction:

`Api -> Application <- Infrastructure -> Domain`

`Application -> Domain`

Not allowed:
- Application referencing Infrastructure concrete services directly.
- Domain referencing Application/Infrastructure/API.

## Frontend architecture

- `services/` for API/realtime transport clients.
- `state/` for controllers (screen orchestration/state).
- `screens/` for route-level UI composition.
- `widgets/` for reusable UI components.
- `theme/` for palette/spacing/text tokens.

## Realtime

- SignalR hub endpoint: `/hubs/lobby`
- Event used by frontend: `lobbyUpdated`

## Testing

- Unit tests: `backend/Encore.Api.Tests`
- Integration contract tests: `backend/Encore.Api.IntegrationTests`
- Frontend static/widget checks in local CI script + GitHub workflow.
