using Encore.Domain;

namespace Encore.Infrastructure.Services;

public class EncoreRulesEngine(BoardTemplateProvider templates) : IGameRulesEngine<GameState>
{
    public string GameKey => "encore";
    private static readonly Random Rng = new();

    public GameState NewGame(List<GamePlayerSeed> players)
    {
        return new GameState
        {
            Players = players.Select(p => new PlayerState
            {
                AccountId = p.AccountId,
                Name = p.Name
            }).ToList(),
            Board = BuildTemplateBoard(templates.GetEncoreTemplate()),
            ColumnPoints = BuildColumnPoints(),
            ColorCompletionPoints = BuildColorCompletionPoints(),
            Phase = TurnPhase.NeedRoll
        };
    }

    public GameState NewGame(List<string> playerNames)
        => NewGame(playerNames.Select(name => new GamePlayerSeed(Guid.Empty, name)).ToList());

    public void RollForTurn(GameState state)
    {
        EnsureNotFinished(state);
        if (state.Phase != TurnPhase.NeedRoll) throw new InvalidOperationException("Turn already rolled.");

        state.CurrentRoll = RollDice();
        state.ActiveSelection = null;
        state.ResolvedPlayers.Clear();
        state.Phase = TurnPhase.NeedActiveSelection;
        LogEvent(state, "roll", state.ActivePlayerIndex, $"colors={string.Join(',', state.CurrentRoll.ColorDice)};numbers={string.Join(',', state.CurrentRoll.NumberDice)}");
    }

    public void ActivePlayerSelect(GameState state, ActiveSelectionRequest request)
    {
        EnsureNotFinished(state);
        if (state.Phase != TurnPhase.NeedActiveSelection) throw new InvalidOperationException("Active selection not expected now.");
        if (request.PlayerIndex != state.ActivePlayerIndex) throw new InvalidOperationException("Only active player may select dice.");

        if (request.Pass)
        {
            state.ActiveSelection = null;
            state.Phase = TurnPhase.PlayersResolving;
        LogEvent(state, "active-select", request.PlayerIndex, $"{request.ColorDie}/{request.NumberDie}");
            LogEvent(state, "active-pass", request.PlayerIndex);
            return;
        }

        if (request.ColorDie is null || request.NumberDie is null)
            throw new InvalidOperationException("Color and number die are required when not passing.");

        var available = GetAvailableFromRoll(state.CurrentRoll!);
        if (!available.colorDice.Contains(request.ColorDie.Value) || !available.numberDice.Contains(request.NumberDie.Value))
            throw new InvalidOperationException("Selected dice are not available in current roll.");

        state.ActiveSelection = new SelectedDice(request.ColorDie.Value, request.NumberDie.Value);
        state.Phase = TurnPhase.PlayersResolving;
        LogEvent(state, "active-select", request.PlayerIndex, $"{request.ColorDie}/{request.NumberDie}");
    }

    public DiceRoll GetAvailableDiceForPlayer(GameState state, int playerIndex)
    {
        EnsureNotFinished(state);
        if (state.Phase != TurnPhase.PlayersResolving) throw new InvalidOperationException("Players cannot act before active selection.");
        if (playerIndex < 0 || playerIndex >= state.Players.Count) throw new InvalidOperationException("Invalid player index.");
        if (state.ResolvedPlayers.Contains(playerIndex)) throw new InvalidOperationException("Player already resolved this turn.");

        var (colorDice, numberDice) = GetAvailableFromRoll(state.CurrentRoll!);

        // First 3 active turns: everyone can use all 6 dice (no removal)
        if (state.InitialOpenDraftTurnsRemaining > 0 || state.ActiveSelection is null)
            return new DiceRoll(colorDice, numberDice);

        // After initial turns: active player uses selected pair, others use remaining four dice
        if (playerIndex == state.ActivePlayerIndex)
            return new DiceRoll([state.ActiveSelection.ColorDie], [state.ActiveSelection.NumberDie]);

        RemoveOne(colorDice, state.ActiveSelection.ColorDie);
        RemoveOne(numberDice, state.ActiveSelection.NumberDie);
        return new DiceRoll(colorDice, numberDice);
    }

    public void ResolvePlayerAction(GameState state, PlayerActionRequest request)
    {
        EnsureNotFinished(state);

        var available = GetAvailableDiceForPlayer(state, request.PlayerIndex);
        if (request.Pass)
        {
            MarkPlayerResolved(state, request.PlayerIndex);
            LogEvent(state, "pass", request.PlayerIndex);
            return;
        }

        if (request.ColorDie is null || request.NumberDie is null)
            throw new InvalidOperationException("Color and number die are required when not passing.");

        if (!available.ColorDice.Contains(request.ColorDie.Value) || !available.NumberDice.Contains(request.NumberDie.Value))
            throw new InvalidOperationException("Chosen dice are not available to this player.");

        var move = new MoveRequest(request.PlayerIndex, request.ColorDie.Value, request.NumberDie.Value, request.CellIds ?? []);
        ValidateAndApplyPlacement(state, move);
        LogEvent(state, "move", request.PlayerIndex, $"cells={move.CellIds.Count};color={move.ColorDie};number={move.NumberDie}");
        MarkPlayerResolved(state, request.PlayerIndex);
    }

    public void EnableEncore(GameState state)
    {
        if (!state.EndTriggered) throw new InvalidOperationException("Encore can only be enabled after game-end trigger.");
        if (!state.IsFinished) throw new InvalidOperationException("Encore can only be enabled after the triggering turn is complete.");
        if (state.EncoreEnabled) throw new InvalidOperationException("Encore already enabled.");

        state.EncoreEnabled = true;
        LogEvent(state, "encore-enabled");
        state.EncoreTurnsRemaining = state.Players.Count;
        state.IsFinished = false;
        if (state.Phase == TurnPhase.Finished) state.Phase = TurnPhase.NeedRoll;
            LogEvent(state, "turn-advanced", state.ActivePlayerIndex);
    }

    // Legacy direct move path
    public void ApplyMoveDirect(GameState state, MoveRequest move)
    {
        EnsureNotFinished(state);
        ValidateAndApplyPlacement(state, move);
        AdvanceLegacyTurnState(state);
    }

    public List<object> CalculateScores(GameState state)
    {
        var rows = new List<ScoreRow>();

        foreach (var pair in state.Players.Select((p, i) => new { p, i }))
        {
            var p = pair.p;

            var colPts = p.CompletedColumns.Sum(c =>
            {
                var pts = state.ColumnPoints[c];
                return IsFirstColumnClaimer(state, c, pair.i) ? pts.first : pts.later;
            });

            var colorPts = p.CompletedColors.Sum(color =>
            {
                var pts = state.ColorCompletionPoints[color];
                return IsFirstColorClaimer(state, color, pair.i) ? pts.first : pts.later;
            });

            var jokerBonus = p.JokerMarksRemaining;
            var uncheckedStars = state.Board.Count(c => c.Starred && !p.CheckedCells.Contains(c.Id));
            var starPenalty = Math.Min(uncheckedStars * 2, 30);

            var total = colPts + colorPts + jokerBonus - starPenalty;

            rows.Add(new ScoreRow(
                PlayerIndex: pair.i,
                Player: p.Name,
                Columns: colPts,
                Colors: colorPts,
                JokerBonus: jokerBonus,
                StarPenalty: starPenalty,
                Total: total));
        }

        var rankingKeys = rows
            .Select(r => (r.Total, r.JokerBonus))
            .Distinct()
            .OrderByDescending(k => k.Total)
            .ThenByDescending(k => k.JokerBonus)
            .ToList();

        var top = rankingKeys.FirstOrDefault();
        var topExists = rankingKeys.Count > 0;

        var result = new List<object>(rows.Count);
        foreach (var row in rows)
        {
            var rank = rankingKeys.FindIndex(k => k == (row.Total, row.JokerBonus)) + 1;
            var isWinner = topExists && (row.Total, row.JokerBonus) == top;

            result.Add(new
            {
                playerIndex = row.PlayerIndex,
                player = row.Player,
                columns = row.Columns,
                colors = row.Colors,
                jokerBonus = row.JokerBonus,
                tiebreakExclamationMarks = row.JokerBonus,
                starPenalty = row.StarPenalty,
                total = row.Total,
                rank,
                isWinner
            });
        }

        return result;
    }

    private void ValidateAndApplyPlacement(GameState state, MoveRequest move)
    {
        if (move.PlayerIndex < 0 || move.PlayerIndex >= state.Players.Count) throw new InvalidOperationException("Invalid player.");
        if (move.CellIds.Count == 0) throw new InvalidOperationException("At least one cell must be checked when not passing.");
        if (move.CellIds.Count != move.CellIds.Distinct(StringComparer.Ordinal).Count())
            throw new InvalidOperationException("A move cannot include the same cell more than once.");

        var p = state.Players[move.PlayerIndex];
        var targetColor = move.ColorDie == ColorDieFace.Joker ? ResolveColorFromCells(state, move.CellIds) : (CellColor)move.ColorDie;
        var targetCount = move.NumberDie == NumberDieFace.Joker ? move.CellIds.Count : (int)move.NumberDie;

        if (targetCount < 1 || targetCount > 5) throw new InvalidOperationException("Number die must resolve to 1..5.");
        if (move.CellIds.Count != targetCount) throw new InvalidOperationException("You must check exact number of boxes indicated by the die.");

        var cells = move.CellIds
            .Select(id => state.Board.FirstOrDefault(c => c.Id == id) ?? throw new InvalidOperationException($"Unknown cell {id}"))
            .ToList();

        if (cells.Any(c => c.Color != targetColor)) throw new InvalidOperationException("All checked boxes in a turn must be the same color.");
        if (cells.Any(c => p.CheckedCells.Contains(c.Id))) throw new InvalidOperationException("Cell already checked.");
        if (!IsConnected(cells)) throw new InvalidOperationException("All checks in a turn must connect as one clump.");

        var isFirstMove = p.CheckedCells.Count == 0;
        if (isFirstMove)
        {
            if (!cells.Any(c => c.Column == "H")) throw new InvalidOperationException("At game start, first checked box must be in column H.");
        }
        else
        {
            if (!TouchesExisting(cells, p.CheckedCells, state.Board))
                throw new InvalidOperationException("New checks must touch existing checked boxes orthogonally.");
        }

        var jokersUsed = (move.ColorDie == ColorDieFace.Joker ? 1 : 0) + (move.NumberDie == NumberDieFace.Joker ? 1 : 0);
        if (p.JokerMarksRemaining < jokersUsed) throw new InvalidOperationException("No joker marks remaining.");
        p.JokerMarksRemaining -= jokersUsed;

        foreach (var c in cells) p.CheckedCells.Add(c.Id);
        UpdateCompletions(state, move.PlayerIndex);

        if (p.CompletedColors.Count >= 2 && !state.EndTriggered)
        {
            state.EndTriggered = true;
            state.EndTriggeredByPlayer = move.PlayerIndex;
            p.TriggeredGameEnd = true;
            LogEvent(state, "end-triggered", move.PlayerIndex);
        }
    }

    private void MarkPlayerResolved(GameState state, int playerIndex)
    {
        state.ResolvedPlayers.Add(playerIndex);

        if (state.ResolvedPlayers.Count < state.Players.Count) return;

        state.Turn++;
        state.ActivePlayerIndex = (state.ActivePlayerIndex + 1) % state.Players.Count;
        if (state.InitialOpenDraftTurnsRemaining > 0) state.InitialOpenDraftTurnsRemaining--;

        if (state.EndTriggered && !state.EncoreEnabled)
        {
            state.IsFinished = true;
            state.Phase = TurnPhase.Finished;
            LogEvent(state, "game-finished");
            return;
        }

        if (state.EndTriggered && state.EncoreEnabled)
        {
            state.EncoreTurnsRemaining--;
            if (state.EncoreTurnsRemaining <= 0)
            {
                state.IsFinished = true;
                state.Phase = TurnPhase.Finished;
                LogEvent(state, "game-finished");
                return;
            }
        }

        if (!state.IsFinished)
        {
            state.Phase = TurnPhase.NeedRoll;
            LogEvent(state, "turn-advanced", state.ActivePlayerIndex);
            state.CurrentRoll = null;
            state.ActiveSelection = null;
            state.ResolvedPlayers.Clear();
        }
    }

    private void AdvanceLegacyTurnState(GameState state)
    {
        state.Turn++;
        state.ActivePlayerIndex = (state.ActivePlayerIndex + 1) % state.Players.Count;
        if (state.InitialOpenDraftTurnsRemaining > 0) state.InitialOpenDraftTurnsRemaining--;

        if (state.EndTriggered && !state.EncoreEnabled)
        {
            state.IsFinished = true;
            state.Phase = TurnPhase.Finished;
            LogEvent(state, "game-finished");
            return;
        }
    }

    private static (List<ColorDieFace> colorDice, List<NumberDieFace> numberDice) GetAvailableFromRoll(DiceRoll roll)
        => ([.. roll.ColorDice], [.. roll.NumberDice]);

    private static void RemoveOne<T>(List<T> list, T value) where T : struct
    {
        var idx = list.FindIndex(x => EqualityComparer<T>.Default.Equals(x, value));
        if (idx >= 0) list.RemoveAt(idx);
    }

    private static DiceRoll RollDice() => new(
        Enumerable.Range(0, 3).Select(_ => (ColorDieFace)Rng.Next(0, 6)).ToList(),
        Enumerable.Range(0, 3).Select(_ => (NumberDieFace)(Rng.Next(0, 6) switch
        {
            0 => 0,
            1 => 1,
            2 => 2,
            3 => 3,
            4 => 4,
            _ => 5
        })).ToList());

    private static void EnsureNotFinished(GameState state)
    {
        if (state.IsFinished) throw new InvalidOperationException("Game is finished.");
    }

    private static CellColor ResolveColorFromCells(GameState state, List<string> ids)
    {
        var colors = state.Board.Where(c => ids.Contains(c.Id)).Select(c => c.Color).Distinct().ToList();
        return colors.Count == 1 ? colors[0] : throw new InvalidOperationException("Joker color must resolve to one color.");
    }

    private static bool IsConnected(List<CellDef> cells)
    {
        if (cells.Count == 0) return false;

        var set = cells.ToDictionary(c => (c.X, c.Y));
        var q = new Queue<(int x, int y)>();
        var seen = new HashSet<(int, int)>();
        q.Enqueue((cells[0].X, cells[0].Y));
        seen.Add((cells[0].X, cells[0].Y));

        while (q.Count > 0)
        {
            var (x, y) = q.Dequeue();
            foreach (var n in new[] { (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1) })
            {
                if (set.ContainsKey(n) && seen.Add(n)) q.Enqueue(n);
            }
        }

        return seen.Count == cells.Count;
    }

    private static bool TouchesExisting(List<CellDef> move, HashSet<string> existing, List<CellDef> board)
    {
        var existingCoords = board.Where(c => existing.Contains(c.Id)).Select(c => (c.X, c.Y)).ToHashSet();
        return move.Any(c =>
            existingCoords.Contains((c.X + 1, c.Y)) ||
            existingCoords.Contains((c.X - 1, c.Y)) ||
            existingCoords.Contains((c.X, c.Y + 1)) ||
            existingCoords.Contains((c.X, c.Y - 1)));
    }

    private static void UpdateCompletions(GameState state, int playerIndex)
    {
        var p = state.Players[playerIndex];

        foreach (var col in state.Board.GroupBy(c => c.Column))
        {
            if (p.CompletedColumns.Contains(col.Key)) continue;
            if (col.All(c => p.CheckedCells.Contains(c.Id)))
            {
                p.CompletedColumns.Add(col.Key);
                if (!state.ColumnFirstClaimByPlayerIndex.ContainsKey(col.Key))
                    state.ColumnFirstClaimByPlayerIndex[col.Key] = playerIndex;

                if (!state.ColumnFirstClaimByPlayerIndices.TryGetValue(col.Key, out var firstClaimers))
                {
                    firstClaimers = [];
                    if (state.ColumnFirstClaimByPlayerIndex.TryGetValue(col.Key, out var owner))
                        firstClaimers.Add(owner);
                    state.ColumnFirstClaimByPlayerIndices[col.Key] = firstClaimers;
                }

                if (!state.ColumnFirstClaimTurn.ContainsKey(col.Key))
                    state.ColumnFirstClaimTurn[col.Key] = state.Turn;

                if (state.ColumnFirstClaimTurn[col.Key] == state.Turn)
                    firstClaimers.Add(playerIndex);
            }
        }

        foreach (var color in Enum.GetValues<CellColor>())
        {
            if (p.CompletedColors.Contains(color)) continue;
            var allColor = state.Board.Where(c => c.Color == color).Select(c => c.Id);
            if (allColor.All(id => p.CheckedCells.Contains(id)))
            {
                p.CompletedColors.Add(color);
                if (!state.ColorFirstClaimByPlayerIndex.ContainsKey(color))
                    state.ColorFirstClaimByPlayerIndex[color] = playerIndex;

                if (!state.ColorFirstClaimByPlayerIndices.TryGetValue(color, out var firstClaimers))
                {
                    firstClaimers = [];
                    if (state.ColorFirstClaimByPlayerIndex.TryGetValue(color, out var owner))
                        firstClaimers.Add(owner);
                    state.ColorFirstClaimByPlayerIndices[color] = firstClaimers;
                }

                if (!state.ColorFirstClaimTurn.ContainsKey(color))
                    state.ColorFirstClaimTurn[color] = state.Turn;

                if (state.ColorFirstClaimTurn[color] == state.Turn)
                    firstClaimers.Add(playerIndex);
            }
        }
    }

    private static bool IsFirstColumnClaimer(GameState state, string column, int playerIndex)
    {
        if (state.ColumnFirstClaimByPlayerIndices.TryGetValue(column, out var firstClaimers))
            return firstClaimers.Contains(playerIndex);

        return state.ColumnFirstClaimByPlayerIndex.TryGetValue(column, out var owner) && owner == playerIndex;
    }

    private static bool IsFirstColorClaimer(GameState state, CellColor color, int playerIndex)
    {
        if (state.ColorFirstClaimByPlayerIndices.TryGetValue(color, out var firstClaimers))
            return firstClaimers.Contains(playerIndex);

        return state.ColorFirstClaimByPlayerIndex.TryGetValue(color, out var owner) && owner == playerIndex;
    }

    private static Dictionary<string, (int first, int later)> BuildColumnPoints()
    {
        var top = new[] { 5, 3, 3, 3, 2, 2, 2, 1, 2, 2, 2, 3, 3, 3, 5 };
        var low = new[] { 3, 2, 2, 2, 1, 1, 1, 0, 1, 1, 1, 2, 2, 2, 3 };
        var cols = "ABCDEFGHIJKLMNO".ToCharArray();
        return cols.Select((c, i) => new { c, i }).ToDictionary(x => x.c.ToString(), x => (top[x.i], low[x.i]));
    }

    private static Dictionary<CellColor, (int first, int later)> BuildColorCompletionPoints()
        => new()
        {
            [CellColor.Green] = (5, 3),
            [CellColor.Yellow] = (5, 3),
            [CellColor.Blue] = (5, 3),
            [CellColor.Purple] = (5, 3),
            [CellColor.Orange] = (5, 3)
        };

    private static List<CellDef> BuildTemplateBoard(BoardTemplate template)
    {
        var rows = template.Rows;
        var stars = template.Stars.Select(s => (s.X, s.Y)).ToHashSet();

        var cols = "ABCDEFGHIJKLMNO".ToCharArray();
        var cells = new List<CellDef>();
        var id = 1;

        for (var y = 0; y < rows.Length; y++)
        {
            for (var x = 0; x < rows[y].Length; x++)
            {
                cells.Add(new CellDef
                {
                    Id = $"c{id++}",
                    X = x,
                    Y = y,
                    Column = cols[x].ToString(),
                    Color = rows[y][x] switch
                    {
                        'G' => CellColor.Green,
                        'Y' => CellColor.Yellow,
                        'O' => CellColor.Orange,
                        'B' => CellColor.Blue,
                        _ => CellColor.Purple
                    },
                    Starred = stars.Contains((x, y))
                });
            }
        }

        return cells;
    }


    private static void LogEvent(GameState state, string type, int? playerIndex = null, string? data = null)
    {
        state.Events.Add(new TurnEvent
        {
            Turn = state.Turn,
            Type = type,
            PlayerIndex = playerIndex,
            Data = data ?? string.Empty
        });

        if (state.Events.Count > 400)
            state.Events = state.Events.Skip(state.Events.Count - 400).ToList();
    }

    private sealed record ScoreRow(
        int PlayerIndex,
        string Player,
        int Columns,
        int Colors,
        int JokerBonus,
        int StarPenalty,
        int Total);
}
