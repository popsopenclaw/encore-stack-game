# Encore PDF Rules Validation Matrix

This file maps game rules from the provided PDF to backend implementation and tests.

## Covered rules

- First checked box must start in **Column H**
  - Engine: `ValidateAndApplyPlacement`
  - Test: `FirstMove_MustTouchColumnH`

- Checks in one turn must be one connected clump (orthogonal adjacency only)
  - Engine: `IsConnected` + `TouchesExisting`
  - Test: `Move_CannotBeSplitIntoDisconnectedClumps`

- Exact number of boxes must match die value
  - Engine: `targetCount` validation
  - Test: `Move_RequiresExactNumberOfCells`

- Number joker can only represent 1..5 (never 6)
  - Engine: `targetCount < 1 || targetCount > 5`
  - Test: `NumberJoker_CannotRepresentSix`

- First three active turns: everyone may choose from all six dice
  - Engine: `GetAvailableDiceForPlayer` (`InitialOpenDraftTurnsRemaining > 0`)
  - Test: `FirstThreeTurns_AllPlayersCanUseAllDice`

- After first three turns: active selected pair removed for other players
  - Engine: `GetAvailableDiceForPlayer`
  - Test: `AfterFirstThreeTurns_ActiveChoiceIsRemovedForOthers`

- Column scoring first-vs-later
  - Engine: `CalculateScores` + `ColumnFirstClaimByPlayerIndex`
  - Test: `Scores_UseFirstVsLaterForColumnsAndColors`

- Color completion bonus first-vs-later (5/3 per sheet)
  - Engine: `ColorCompletionPoints` + `ColorFirstClaimByPlayerIndex`
  - Test: `Scores_UseFirstVsLaterForColumnsAndColors`

- Star penalties and remaining joker bonus at end
  - Engine: `CalculateScores`

## Implemented turn flow

- `roll` -> active player `active-select` (or pass) -> each player `action` (or pass)
- optional encore round support after game-end trigger: `/api/gameplay/{sessionId}/encore`

## Remaining fidelity work

- Board layout is still based on photo tracing and should be considered best-effort until final top-down scan calibration.
- Digital UX for the exact physical score strip interactions can still be refined.
