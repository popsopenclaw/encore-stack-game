# Encore Rules Validation Matrix

This file maps the multiplayer printed rules to backend implementation and tests.

## Scope

- In scope: standard multiplayer game flow (1 to 6 players) and multiplayer scoring rules.
- Out of scope: solo-mode special rules (2 color dice + 2 number dice, slash tracking by letter field, 30-turn solo rank table).

## Dice flow rules

- Active player rolls 3 color dice + 3 number dice.
  - Engine: `RollForTurn`

- Active player selects one color die + one number die, then other players use remaining dice.
  - Engine: `ActivePlayerSelect`, `GetAvailableDiceForPlayer`
  - Test: `AfterFirstThreeTurns_ActiveChoiceIsRemovedForOthers`

- First three active turns exception: everyone may choose from all six dice and active player does not remove dice.
  - Engine: `GetAvailableDiceForPlayer` with `InitialOpenDraftTurnsRemaining`
  - Test: `FirstThreeTurns_AllPlayersCanUseAllDice`

- Passing is allowed for any player; if active passes, other players may still choose from all six dice.
  - Engine: `ActivePlayerSelect` + `GetAvailableDiceForPlayer`
  - Tests: `AllPlayersPass_AdvancesTurnAndActivePlayer`, `ActivePass_AfterOpenDraft_AllowsOthersToUseAllSixDice`

## Placement rules

- First checked box must be in column H.
  - Engine: `ValidateAndApplyPlacement`
  - Test: `FirstMove_MustTouchColumnH`

- Exact die value must be checked (no partial use).
  - Engine: `ValidateAndApplyPlacement`
  - Test: `Move_RequiresExactNumberOfCells`

- Checked boxes in a move must be one orthogonally connected clump.
  - Engine: `IsConnected`
  - Test: `Move_CannotBeSplitIntoDisconnectedClumps`

- Move must connect orthogonally to already checked boxes after the opening move.
  - Engine: `TouchesExisting`
  - Test: `Move_MustTouchExistingOrthogonally_NotDiagonally`

- Selected cells must all match the chosen color.
  - Engine: `ValidateAndApplyPlacement`
  - Test: `Move_MustUseSingleChosenColor`

- A move must include at least one non-duplicate cell selection.
  - Engine: `ValidateAndApplyPlacement`
  - Tests: `Move_RequiresAtLeastOneCell`, `Move_CannotIncludeDuplicateCellIds`

## Joker rules

- Number joker resolves to 1..5 only (never 6).
  - Engine: `targetCount` validation in `ValidateAndApplyPlacement`
  - Test: `NumberJoker_CannotRepresentSix`

- Color joker resolves to the selected cells' single color.
  - Engine: `ResolveColorFromCells`

- Joker usage consumes exclamation marks (one mark per joker die used).
  - Engine: `ValidateAndApplyPlacement` (`jokersUsed` and `JokerMarksRemaining`)
  - Tests: `JokerUse_ConsumesOneMarkPerJokerDie`, `JokerUse_FailsWhenNoMarksRemaining`

## Column and color bonus claiming

- First claimant receives high value; later claimants receive low value.
  - Engine: `UpdateCompletions`, `CalculateScores`
  - Test: `Scores_UseFirstVsLaterForColumnsAndColors`

- If multiple players complete the same column in the same turn, all receive high value.
  - Engine: `UpdateCompletions` with `ColumnFirstClaimByPlayerIndices` and `ColumnFirstClaimTurn`
  - Test: `SameTurn_ColumnClaimers_AllReceiveFirstPoints`

- If multiple players complete the same color in the same turn, all receive high value.
  - Engine: `UpdateCompletions` with `ColorFirstClaimByPlayerIndices` and `ColorFirstClaimTurn`
  - Test: `SameTurn_ColorClaimers_AllReceiveFirstPoints`

## End-of-game and scoring rules

- Game-end is triggered when a player reaches a second completed color.
  - Engine: `ValidateAndApplyPlacement`

- Game finishes after the current turn resolves (remaining players still act in that turn).
  - Engine: `MarkPlayerResolved`
  - Test: `EndTrigger_FinishesOnlyAfterAllPlayersResolveCurrentTurn`

- Optional encore round can be enabled only after the triggering turn is complete.
  - Engine: `EnableEncore`
  - Test: `Encore_CanOnlyBeEnabledAfterEndTrigger`

- Score includes:
  - column points
  - color completion bonus points
  - remaining exclamation marks (+1 each)
  - unchecked stars (-2 each, capped at -30)
  - winner metadata (`rank`, `isWinner`) with exclamation marks as tiebreak when totals tie
  - Engine: `CalculateScores`
  - Tests: `Scores_StarPenalty_IsCappedAtThirty`, `Scores_WinnerUsesExclamationMarksAsTieBreak`, `Scores_WinnerPrefersHigherTotalBeforeTieBreak`

## Fidelity notes

- Board layout is based on the bundled template (`backend/Encore.Domain/Templates/encore-default.json`) and should be treated as the source of truth for digital play.
