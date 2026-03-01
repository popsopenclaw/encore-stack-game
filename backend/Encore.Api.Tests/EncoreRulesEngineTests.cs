using Encore.Api.Domain;
using Encore.Api.Services;

namespace Encore.Api.Tests;

public class EncoreRulesEngineTests
{
    private readonly EncoreRulesEngine _engine = new();

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
}
