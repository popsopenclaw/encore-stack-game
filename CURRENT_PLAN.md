# CURRENT_PLAN.md

Goal: implement the remaining roadmap in a safe, incremental order while keeping backend/frontend compatibility at every step.

## Order of implementation (recommended)

1. **Real multiplayer backend foundation (Lobby + Realtime) [DONE]**
   - [x] Add persistent lobby model in backend (Postgres via EF Core)
   - [x] Add lobby service/use-case and HTTP endpoints (create/join/leave/list)
   - [x] Add SignalR hub for lobby/game realtime updates
   - [x] Add integration tests for lobby endpoints + hub handshake

2. **Frontend multiplayer flow wiring [DONE]**
   - [x] Replace frontend-only lobby state with backend-backed lobby API
   - [x] Add realtime subscription client (SignalR)
   - [x] Reflect lobby participant updates in Home/Create/Join screens

3. **Game interaction UX rework (contract-aligned) [DONE]**
   - [x] Add phase-aware controls: select dice, pass, submit action
   - [x] Add board cell selection + move payload builder
   - [x] Add clear error handling surfaced from backend validations

4. **Replay + audit timeline UI [DONE]**
   - [x] Show events stream in-game from `/events`
   - [x] Add score panel and turn history widgets

5. **Rule-fidelity hardening + regression coverage [PARTIAL]**
   - [x] Add more regression cases from PDF scenarios
   - [ ] Add frontend API contract parsing tests for core endpoints

6. **Polish and cleanup [IN PROGRESS]**
   - [x] Refine screen theme fidelity to board references
   - [ ] Remove dead code and update docs (`README`, `TURN_FLOW`, `RULES_VALIDATION`)

## Execution notes
- Always keep `scripts/ci-local.sh` green after each phase.
- Ship in small commits by phase so rollback is easy.
- Do not break existing API paths currently used by frontend.
