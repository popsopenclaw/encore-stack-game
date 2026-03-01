using System.Text.Json.Serialization;

namespace Encore.Api.Domain;

public class GameState
{
    public string SessionId { get; set; } = Guid.NewGuid().ToString("N");
    public int Turn { get; set; } = 1;
    public int ActivePlayerIndex { get; set; }
    public int InitialOpenDraftTurnsRemaining { get; set; } = 3;

    [JsonConverter(typeof(JsonStringEnumConverter))]
    public TurnPhase Phase { get; set; } = TurnPhase.NeedRoll;

    public DiceRoll? CurrentRoll { get; set; }
    public SelectedDice? ActiveSelection { get; set; }
    public HashSet<int> ResolvedPlayers { get; set; } = [];

    public bool EndTriggered { get; set; }
    public int? EndTriggeredByPlayer { get; set; }
    public bool EncoreEnabled { get; set; }
    public int EncoreTurnsRemaining { get; set; }

    public List<PlayerState> Players { get; set; } = [];
    public List<CellDef> Board { get; set; } = [];
    public Dictionary<string, int> ColumnFirstClaimByPlayerIndex { get; set; } = new();
    public Dictionary<CellColor, int> ColorFirstClaimByPlayerIndex { get; set; } = new();
    public Dictionary<string, (int first, int later)> ColumnPoints { get; set; } = new();
    public Dictionary<CellColor, (int first, int later)> ColorCompletionPoints { get; set; } = new();

    public bool IsFinished { get; set; }
    public List<TurnEvent> Events { get; set; } = [];
}

public class TurnEvent
{
    public int Turn { get; set; }
    public DateTimeOffset At { get; set; } = DateTimeOffset.UtcNow;
    public string Type { get; set; } = string.Empty;
    public int? PlayerIndex { get; set; }
    public string Data { get; set; } = string.Empty;
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
public record SelectedDice(ColorDieFace ColorDie, NumberDieFace NumberDie);

public record StartGameRequest(List<string> PlayerNames);
public record ActiveSelectionRequest(int PlayerIndex, ColorDieFace? ColorDie, NumberDieFace? NumberDie, bool Pass);
public record PlayerActionRequest(int PlayerIndex, ColorDieFace? ColorDie, NumberDieFace? NumberDie, List<string>? CellIds, bool Pass);
public record MoveRequest(int PlayerIndex, ColorDieFace ColorDie, NumberDieFace NumberDie, List<string> CellIds);

public enum TurnPhase
{
    NeedRoll,
    NeedActiveSelection,
    PlayersResolving,
    Finished
}
