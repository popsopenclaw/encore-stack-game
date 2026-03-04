# Turn Flow (Encore)

This is the API order for one complete turn:

1. `POST /api/gameplay/{sessionId}/roll`
2. Active player picks dice or passes:
   - `POST /api/gameplay/{sessionId}/active-select`
3. For each player (including active), resolve action:
   - check available dice: `GET /api/gameplay/{sessionId}/available-dice/{playerIndex}`
   - submit move/pass: `POST /api/gameplay/{sessionId}/action`
4. Repeat from step 1 until end trigger.
5. Optional Encore round:
   - `POST /api/gameplay/{sessionId}/encore`

## Notes

- First 3 active turns: all players use all 6 dice.
- Afterwards: active selected pair is removed for non-active players.
- Number joker resolves only to 1..5.
- Start must touch column H.
- Scoring endpoint: `GET /api/gameplay/{sessionId}/score`.
- Events timeline endpoint: `GET /api/gameplay/{sessionId}/events`.

## Lobby + realtime flow

1. Create lobby: `POST /api/lobby`
2. Join lobby: `POST /api/lobby/join`
3. Subscribe realtime group on SignalR hub `/hubs/lobby`
4. Receive `lobbyUpdated` events as members join/leave
5. Leave lobby: `POST /api/lobby/{code}/leave`
