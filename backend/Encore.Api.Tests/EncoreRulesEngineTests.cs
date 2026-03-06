using Encore.Domain;
using Encore.Infrastructure.Services;

namespace Encore.Api.Tests;

public class EncoreRulesEngineTests
{
    private readonly EncoreRulesEngine _engine;

    public EncoreRulesEngineTests()
    {
        var env = new FakeHostEnvironment
        {
            ContentRootPath = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../Encore.Api"))
        };
        _engine = new EncoreRulesEngine(new BoardTemplateProvider(env));
    }

    [Fact]
    public void FirstMove_MustTouchColumnH()
    {
        var state = _engine.NewGame(["A"]);
        var nonH = state.Board.First(c => c.Column != "H");

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, (ColorDieFace)nonH.Color, NumberDieFace.One, [nonH.Id])));

        Assert.Contains("column H", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void AfterFirstThreeTurns_ActiveChoiceIsRemovedForOthers()
    {
        var state = _engine.NewGame(["A", "B"]);
        state.InitialOpenDraftTurnsRemaining = 0;

        _engine.RollForTurn(state);

        var chosenColor = state.CurrentRoll!.ColorDice[0];
        var chosenNumber = state.CurrentRoll.NumberDice[0];

        _engine.ActivePlayerSelect(state, new ActiveSelectionRequest(0, chosenColor, chosenNumber, false));

        var active = _engine.GetAvailableDiceForPlayer(state, 0);
        var other = _engine.GetAvailableDiceForPlayer(state, 1);

        Assert.Single(active.ColorDice);
        Assert.Single(active.NumberDice);
        Assert.Equal(chosenColor, active.ColorDice[0]);
        Assert.Equal(chosenNumber, active.NumberDice[0]);

        Assert.Equal(2, other.ColorDice.Count);
        Assert.Equal(2, other.NumberDice.Count);
    }

    [Fact]
    public void FirstThreeTurns_AllPlayersCanUseAllDice()
    {
        var state = _engine.NewGame(["A", "B"]);
        state.InitialOpenDraftTurnsRemaining = 3;

        _engine.RollForTurn(state);
        var chosenColor = state.CurrentRoll!.ColorDice[0];
        var chosenNumber = state.CurrentRoll.NumberDice[0];

        _engine.ActivePlayerSelect(state, new ActiveSelectionRequest(0, chosenColor, chosenNumber, false));

        var other = _engine.GetAvailableDiceForPlayer(state, 1);
        Assert.Equal(3, other.ColorDice.Count);
        Assert.Equal(3, other.NumberDice.Count);
    }

    [Fact]
    public void Move_RequiresExactNumberOfCells()
    {
        var state = _engine.NewGame(["A"]);
        var hCell = state.Board.First(c => c.Column == "H");

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, (ColorDieFace)hCell.Color, NumberDieFace.Two, [hCell.Id])));

        Assert.Contains("exact", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Move_CannotBeSplitIntoDisconnectedClumps()
    {
        var state = _engine.NewGame(["A"]);
        var byColor = state.Board.GroupBy(c => c.Color).First(g => g.Count() > 6).ToList();

        var first = byColor[0];
        var far = byColor.Last(c => Math.Abs(c.X - first.X) + Math.Abs(c.Y - first.Y) > 2);

        // force first move to include H by making a valid opening first
        var h = state.Board.First(c => c.Column == "H");
        _engine.ApplyMoveDirect(state, new MoveRequest(0, (ColorDieFace)h.Color, NumberDieFace.One, [h.Id]));

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, (ColorDieFace)first.Color, NumberDieFace.Two, [first.Id, far.Id])));

        Assert.Contains("connect", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Move_MustUseSingleChosenColor()
    {
        var state = _engine.NewGame(["A"]);
        var pair = FindOrthogonallyAdjacentPair(state.Board, (a, b) => a.Color != b.Color);

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, (ColorDieFace)pair.a.Color, NumberDieFace.Two, [pair.a.Id, pair.b.Id])));

        Assert.Contains("same color", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Move_MustTouchExistingOrthogonally_NotDiagonally()
    {
        var state = _engine.NewGame(["A"]);
        var pair = FindDiagonallyAdjacentPair(state.Board, (a, b) => a.Color == b.Color);

        state.Players[0].CheckedCells.Add(pair.a.Id);

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, (ColorDieFace)pair.b.Color, NumberDieFace.One, [pair.b.Id])));

        Assert.Contains("orthogonally", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Move_RequiresAtLeastOneCell()
    {
        var state = _engine.NewGame(["A"]);

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, ColorDieFace.Blue, NumberDieFace.One, [])));

        Assert.Contains("at least one", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Move_CannotIncludeDuplicateCellIds()
    {
        var state = _engine.NewGame(["A"]);
        var hCell = state.Board.First(c => c.Column == "H");

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, (ColorDieFace)hCell.Color, NumberDieFace.Two, [hCell.Id, hCell.Id])));

        Assert.Contains("same cell", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void NumberJoker_CannotRepresentSix()
    {
        var state = _engine.NewGame(["A"]);
        var color = state.Board.First(c => c.Column == "H").Color;
        var six = state.Board.Where(c => c.Color == color).Take(6).Select(c => c.Id).ToList();

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, (ColorDieFace)color, NumberDieFace.Joker, six)));

        Assert.Contains("1..5", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void JokerUse_ConsumesOneMarkPerJokerDie()
    {
        var state = _engine.NewGame(["A"]);
        var hCell = state.Board.First(c => c.Column == "H");
        var neighbor = state.Board.First(c => Math.Abs(c.X - hCell.X) + Math.Abs(c.Y - hCell.Y) == 1);

        _engine.ApplyMoveDirect(state, new MoveRequest(0, ColorDieFace.Joker, NumberDieFace.One, [hCell.Id]));
        _engine.ApplyMoveDirect(state, new MoveRequest(0, ColorDieFace.Joker, NumberDieFace.Joker, [neighbor.Id]));

        Assert.Equal(5, state.Players[0].JokerMarksRemaining);
    }

    [Fact]
    public void JokerUse_FailsWhenNoMarksRemaining()
    {
        var state = _engine.NewGame(["A"]);
        var hCell = state.Board.First(c => c.Column == "H");
        state.Players[0].JokerMarksRemaining = 0;

        var ex = Assert.Throws<InvalidOperationException>(() =>
            _engine.ApplyMoveDirect(state, new MoveRequest(0, ColorDieFace.Joker, NumberDieFace.One, [hCell.Id])));

        Assert.Contains("joker marks", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Scores_UseFirstVsLaterForColumnsAndColors()
    {
        var state = _engine.NewGame(["A", "B"]);

        state.Players[0].CompletedColumns.Add("A");
        state.Players[1].CompletedColumns.Add("A");
        state.ColumnFirstClaimByPlayerIndex["A"] = 0;

        state.Players[0].CompletedColors.Add(CellColor.Green);
        state.Players[1].CompletedColors.Add(CellColor.Green);
        state.ColorFirstClaimByPlayerIndex[CellColor.Green] = 1;

        var json = System.Text.Json.JsonSerializer.Serialize(_engine.CalculateScores(state));
        var arr = System.Text.Json.JsonDocument.Parse(json).RootElement;

        var aCombined = arr[0].GetProperty("columns").GetInt32() + arr[0].GetProperty("colors").GetInt32();
        var bCombined = arr[1].GetProperty("columns").GetInt32() + arr[1].GetProperty("colors").GetInt32();

        // A gets first column(5) + later color(3)
        Assert.Equal(8, aCombined);
        // B gets later column(3) + first color(5)
        Assert.Equal(8, bCombined);
    }

    [Fact]
    public void Scores_StarPenalty_IsCappedAtThirty()
    {
        var state = _engine.NewGame(["A"]);
        foreach (var c in state.Board) c.Starred = true;

        var json = System.Text.Json.JsonSerializer.Serialize(_engine.CalculateScores(state));
        var arr = System.Text.Json.JsonDocument.Parse(json).RootElement;

        Assert.Equal(30, arr[0].GetProperty("starPenalty").GetInt32());
    }

    [Fact]
    public void Scores_WinnerUsesExclamationMarksAsTieBreak()
    {
        var state = _engine.NewGame(["A", "B"]);
        foreach (var c in state.Board) c.Starred = false;

        state.Players[0].JokerMarksRemaining = 5;
        state.Players[1].JokerMarksRemaining = 6;
        state.Players[0].CompletedColumns.Add("A");
        state.ColumnFirstClaimByPlayerIndex["A"] = 0;
        state.Players[1].CompletedColumns.UnionWith(["B", "C"]);

        var json = System.Text.Json.JsonSerializer.Serialize(_engine.CalculateScores(state));
        var arr = System.Text.Json.JsonDocument.Parse(json).RootElement;

        Assert.Equal(10, arr[0].GetProperty("total").GetInt32());
        Assert.Equal(10, arr[1].GetProperty("total").GetInt32());
        Assert.False(arr[0].GetProperty("isWinner").GetBoolean());
        Assert.True(arr[1].GetProperty("isWinner").GetBoolean());
        Assert.Equal(1, arr[1].GetProperty("rank").GetInt32());
        Assert.Equal(6, arr[1].GetProperty("tiebreakExclamationMarks").GetInt32());
    }

    [Fact]
    public void Scores_WinnerPrefersHigherTotalBeforeTieBreak()
    {
        var state = _engine.NewGame(["A", "B"]);
        foreach (var c in state.Board) c.Starred = false;

        state.Players[0].JokerMarksRemaining = 8;
        state.Players[1].JokerMarksRemaining = 1;
        state.Players[0].CompletedColumns.Add("B"); // later=2
        state.Players[1].CompletedColumns.Add("A"); // first=5
        state.ColumnFirstClaimByPlayerIndex["A"] = 1;

        var json = System.Text.Json.JsonSerializer.Serialize(_engine.CalculateScores(state));
        var arr = System.Text.Json.JsonDocument.Parse(json).RootElement;

        Assert.Equal(10, arr[0].GetProperty("total").GetInt32());
        Assert.Equal(6, arr[1].GetProperty("total").GetInt32());
        Assert.True(arr[0].GetProperty("isWinner").GetBoolean());
        Assert.False(arr[1].GetProperty("isWinner").GetBoolean());
        Assert.Equal(1, arr[0].GetProperty("rank").GetInt32());
    }

    [Fact]
    public void AllPlayersPass_AdvancesTurnAndActivePlayer()
    {
        var state = _engine.NewGame(["A", "B"]);

        _engine.RollForTurn(state);
        _engine.ActivePlayerSelect(state, new ActiveSelectionRequest(0, null, null, true));

        _engine.ResolvePlayerAction(state, new PlayerActionRequest(0, null, null, null, true));
        _engine.ResolvePlayerAction(state, new PlayerActionRequest(1, null, null, null, true));

        Assert.Equal(2, state.Turn);
        Assert.Equal(1, state.ActivePlayerIndex);
        Assert.Equal(TurnPhase.NeedRoll, state.Phase);
    }

    [Fact]
    public void ActivePass_AfterOpenDraft_AllowsOthersToUseAllSixDice()
    {
        var state = _engine.NewGame(["A", "B"]);
        state.InitialOpenDraftTurnsRemaining = 0;

        _engine.RollForTurn(state);
        _engine.ActivePlayerSelect(state, new ActiveSelectionRequest(0, null, null, true));

        var other = _engine.GetAvailableDiceForPlayer(state, 1);
        Assert.Equal(3, other.ColorDice.Count);
        Assert.Equal(3, other.NumberDice.Count);
    }

    [Fact]
    public void EndTrigger_FinishesOnlyAfterAllPlayersResolveCurrentTurn()
    {
        var state = _engine.NewGame(["A", "B"]);
        var hCell = state.Board.First(c => c.Column == "H");

        state.Phase = TurnPhase.PlayersResolving;
        state.CurrentRoll = new DiceRoll([(ColorDieFace)hCell.Color, ColorDieFace.Blue, ColorDieFace.Green], [NumberDieFace.One, NumberDieFace.Two, NumberDieFace.Three]);
        state.Players[0].CompletedColors.Add(CellColor.Green);
        state.Players[0].CompletedColors.Add(CellColor.Blue);

        _engine.ResolvePlayerAction(state, new PlayerActionRequest(0, (ColorDieFace)hCell.Color, NumberDieFace.One, [hCell.Id], false));

        Assert.True(state.EndTriggered);
        Assert.False(state.IsFinished);
        Assert.Equal(TurnPhase.PlayersResolving, state.Phase);

        _engine.ResolvePlayerAction(state, new PlayerActionRequest(1, null, null, null, true));

        Assert.True(state.IsFinished);
        Assert.Equal(TurnPhase.Finished, state.Phase);
    }

    [Fact]
    public void SameTurn_ColumnClaimers_AllReceiveFirstPoints()
    {
        var state = _engine.NewGame(["A", "B"]);
        var column = state.Board.Where(c => c.Column == "A").ToList();
        var missing = column[0];

        foreach (var p in state.Players)
        {
            foreach (var c in column.Skip(1))
                p.CheckedCells.Add(c.Id);
        }

        state.Phase = TurnPhase.PlayersResolving;
        state.CurrentRoll = new DiceRoll([(ColorDieFace)missing.Color, ColorDieFace.Joker, ColorDieFace.Blue], [NumberDieFace.One, NumberDieFace.Two, NumberDieFace.Three]);

        _engine.ResolvePlayerAction(state, new PlayerActionRequest(0, (ColorDieFace)missing.Color, NumberDieFace.One, [missing.Id], false));
        _engine.ResolvePlayerAction(state, new PlayerActionRequest(1, (ColorDieFace)missing.Color, NumberDieFace.One, [missing.Id], false));

        Assert.True(state.ColumnFirstClaimByPlayerIndices["A"].SetEquals([0, 1]));

        var json = System.Text.Json.JsonSerializer.Serialize(_engine.CalculateScores(state));
        var arr = System.Text.Json.JsonDocument.Parse(json).RootElement;

        Assert.Equal(5, arr[0].GetProperty("columns").GetInt32());
        Assert.Equal(5, arr[1].GetProperty("columns").GetInt32());
    }

    [Fact]
    public void SameTurn_ColorClaimers_AllReceiveFirstPoints()
    {
        var state = _engine.NewGame(["A", "B"]);
        var targetColor = CellColor.Green;
        var colorCells = state.Board.Where(c => c.Color == targetColor).ToList();
        var missing = colorCells.First(c =>
            colorCells.Any(n => Math.Abs(c.X - n.X) + Math.Abs(c.Y - n.Y) == 1));

        foreach (var p in state.Players)
        {
            foreach (var c in colorCells.Where(c => c.Id != missing.Id))
                p.CheckedCells.Add(c.Id);
        }

        state.Phase = TurnPhase.PlayersResolving;
        state.CurrentRoll = new DiceRoll([(ColorDieFace)targetColor, ColorDieFace.Joker, ColorDieFace.Blue], [NumberDieFace.One, NumberDieFace.Two, NumberDieFace.Three]);

        _engine.ResolvePlayerAction(state, new PlayerActionRequest(0, (ColorDieFace)targetColor, NumberDieFace.One, [missing.Id], false));
        _engine.ResolvePlayerAction(state, new PlayerActionRequest(1, (ColorDieFace)targetColor, NumberDieFace.One, [missing.Id], false));

        Assert.True(state.ColorFirstClaimByPlayerIndices[targetColor].SetEquals([0, 1]));

        var json = System.Text.Json.JsonSerializer.Serialize(_engine.CalculateScores(state));
        var arr = System.Text.Json.JsonDocument.Parse(json).RootElement;

        Assert.Equal(5, arr[0].GetProperty("colors").GetInt32());
        Assert.Equal(5, arr[1].GetProperty("colors").GetInt32());
    }

    [Fact]
    public void Encore_CanOnlyBeEnabledAfterEndTrigger()
    {
        var state = _engine.NewGame(["A", "B"]);
        Assert.Throws<InvalidOperationException>(() => _engine.EnableEncore(state));

        state.EndTriggered = true;
        Assert.Throws<InvalidOperationException>(() => _engine.EnableEncore(state));

        state.IsFinished = true;
        state.Phase = TurnPhase.Finished;

        _engine.EnableEncore(state);

        Assert.True(state.EncoreEnabled);
        Assert.Equal(state.Players.Count, state.EncoreTurnsRemaining);
        Assert.False(state.IsFinished);
        Assert.Equal(TurnPhase.NeedRoll, state.Phase);
    }

    private static (CellDef a, CellDef b) FindOrthogonallyAdjacentPair(List<CellDef> board, Func<CellDef, CellDef, bool> predicate)
    {
        foreach (var a in board)
        {
            foreach (var b in board)
            {
                if (Math.Abs(a.X - b.X) + Math.Abs(a.Y - b.Y) != 1) continue;
                if (predicate(a, b)) return (a, b);
            }
        }

        throw new InvalidOperationException("No orthogonally adjacent pair found.");
    }

    private static (CellDef a, CellDef b) FindDiagonallyAdjacentPair(List<CellDef> board, Func<CellDef, CellDef, bool> predicate)
    {
        foreach (var a in board)
        {
            foreach (var b in board)
            {
                if (Math.Abs(a.X - b.X) != 1 || Math.Abs(a.Y - b.Y) != 1) continue;
                if (predicate(a, b)) return (a, b);
            }
        }

        throw new InvalidOperationException("No diagonally adjacent pair found.");
    }
}
