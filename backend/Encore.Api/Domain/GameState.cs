using System.Text.Json.Serialization;

namespace Encore.Api.Domain;

public class GameState
{
    public string SessionId { get; set; } = Guid.NewGuid().ToString("N");
    public int Turn { get; set; } = 1;
    public int ActivePlayerIndex { get; set; }
    public int InitialOpenDraftTurnsRemaining { get; set; } = 3;
    public List<PlayerState> Players { get; set; } = [];
    public List<CellDef> Board { get; set; } = [];
    public Dictionary<string, int> ColumnFirstClaimByPlayerIndex { get; set; } = new();
    public Dictionary<string, (int first, int later)> ColumnPoints { get; set; } = new();
    public bool IsFinished { get; set; }
}

public class PlayerState
{
    public string Name { get; set; } = "Player";
    public HashSet<string> CheckedCells { get; set; } = [];
    public int JokerMarksRemaining { get; set; } = 8;
    public HashSet<string> CompletedColumns { get; set; } = [];
    public HashSet<CellColor> CompletedColors { get; set; } = [];
    public bool TriggeredGameEnd { get; set; }
}

public class CellDef
{
    public string Id { get; set; } = string.Empty;
    public int X { get; set; }
    public int Y { get; set; }
    public string Column { get; set; } = "A";
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public CellColor Color { get; set; }
    public bool Starred { get; set; }
}

public record DiceRoll(List<ColorDieFace> ColorDice, List<NumberDieFace> NumberDice);

public record MoveRequest(int PlayerIndex, ColorDieFace ColorDie, NumberDieFace NumberDie, List<string> CellIds);
