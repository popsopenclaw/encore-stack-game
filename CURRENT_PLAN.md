# CURRENT_PLAN.md

Goal: Production-readiness hardening for reliable real-world multiplayer usage.

## Phase 1 — Auth/session resilience
- [ ] Add token/session validation middleware behavior checks (401 flow consistency).
- [ ] Add frontend auth guard + session bootstrap strategy (recover persisted JWT cleanly).
- [ ] Add explicit logout flow (clear JWT + disconnect realtime + reset local state).
- [ ] Add integration tests for auth-protected endpoints with missing/invalid token.

## Phase 2 — Realtime reliability
- [ ] Add frontend SignalR reconnect strategy with exponential backoff.
- [ ] Re-join lobby group automatically after reconnect.
- [ ] Add connection status indicator in UI (connecting/connected/reconnecting/disconnected).
- [ ] Add backend-safe idempotency for join/leave notifications to avoid duplicate state churn.

## Phase 3 — Lobby governance + permissions
- [ ] Enforce host-only actions where needed (start game, kick, settings changes).
- [ ] Add host transfer when current host leaves.
- [ ] Add lobby lifecycle rules (empty lobby cleanup, stale lobby expiration policy).
- [ ] Add integration tests for permission boundaries and host transfer scenarios.

## Phase 4 — Gameplay robustness
- [ ] Add optimistic UI safeguards + rollback on server rejection.
- [ ] Add explicit phase-lock UI (disable invalid actions by phase).
- [ ] Add conflict-safe refresh (if state changed remotely, merge/refresh flow).
- [ ] Extend regression suite with multi-turn scenarios and pass/encore edge-cases.

## Phase 5 — End-to-end confidence
- [ ] Add API-level E2E playthrough test (create lobby -> join -> start -> turns -> score/events).
- [ ] Add frontend integration/widget flow tests for lobby->game journey.
- [ ] Add smoke script for local verification (single command) before release.

## Phase 6 — Ops hardening for VM deploy
- [ ] Add health/readiness docs and checks for API + DB + Valkey + migrate service.
- [ ] Add backup/restore validation drill docs and script checks.
- [ ] Add minimal runtime observability (structured logs + key error paths).
- [ ] Add release checklist (env vars, migrations, rollback procedure).

## Deliverable rule (for every phase)
- [ ] Keep `./scripts/ci-local.sh` green.
- [ ] Commit per step with clear message.
- [ ] Update docs as behavior changes.
