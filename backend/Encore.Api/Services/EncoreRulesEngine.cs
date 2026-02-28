using Encore.Api.Domain;

namespace Encore.Api.Services;

public class EncoreRulesEngine
{
    private static readonly Random Rng = new();

    public GameState NewGame(List<string> playerNames)
    {
        var state = new GameState
        {
            Players = playerNames.Select(n => new PlayerState { Name = n }).ToList(),
            Board = BuildTemplateBoard(),
            ColumnPoints = BuildColumnPoints()
        };
        return state;
    }

    public DiceRoll RollDice() => new(
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

    public void ApplyMove(GameState state, MoveRequest move)
    {
        if (state.IsFinished) throw new InvalidOperationException("Game already finished.");
        if (move.PlayerIndex < 0 || move.PlayerIndex >= state.Players.Count) throw new InvalidOperationException("Invalid player.");

        var p = state.Players[move.PlayerIndex];
        var targetColor = move.ColorDie == ColorDieFace.Joker ? ResolveColorFromCells(state, move.CellIds) : (CellColor)move.ColorDie;
        var targetCount = move.NumberDie == NumberDieFace.Joker ? move.CellIds.Count : (int)move.NumberDie;

        if (targetCount < 1 || targetCount > 5) throw new InvalidOperationException("Number die must resolve to 1..5.");
        if (move.CellIds.Count != targetCount) throw new InvalidOperationException("You must mark exact die value.");

        var cells = move.CellIds.Select(id => state.Board.FirstOrDefault(c => c.Id == id) ?? throw new InvalidOperationException($"Unknown cell {id}")).ToList();

        if (cells.Any(c => c.Color != targetColor)) throw new InvalidOperationException("All marked cells must match chosen color.");
        if (cells.Any(c => p.CheckedCells.Contains(c.Id))) throw new InvalidOperationException("Cell already checked.");
        if (!IsConnected(cells)) throw new InvalidOperationException("Marked cells must form one connected clump.");

        var isFirstMove = p.CheckedCells.Count == 0;
        if (isFirstMove)
        {
            if (!cells.Any(c => c.Column == "H")) throw new InvalidOperationException("First move must include column H.");
        }
        else
        {
            if (!TouchesExisting(cells, p.CheckedCells, state.Board)) throw new InvalidOperationException("Move must touch existing checked cells orthogonally.");
        }

        var jokersUsed = (move.ColorDie == ColorDieFace.Joker ? 1 : 0) + (move.NumberDie == NumberDieFace.Joker ? 1 : 0);
        if (p.JokerMarksRemaining < jokersUsed) throw new InvalidOperationException("No joker marks left.");
        p.JokerMarksRemaining -= jokersUsed;

        foreach (var c in cells) p.CheckedCells.Add(c.Id);

        UpdateCompletions(state, move.PlayerIndex);

        if (p.CompletedColors.Count >= 2)
        {
            p.TriggeredGameEnd = true;
            state.IsFinished = true;
        }

        state.Turn++;
        state.ActivePlayerIndex = (state.ActivePlayerIndex + 1) % state.Players.Count;
        if (state.InitialOpenDraftTurnsRemaining > 0) state.InitialOpenDraftTurnsRemaining--;
    }


    public List<object> CalculateScores(GameState state)
    {
        var result = new List<object>();
        foreach (var pair in state.Players.Select((p,i)=>new{p,i}))
        {
            var p = pair.p;
            var colPts = p.CompletedColumns.Sum(c =>
            {
                var pts = state.ColumnPoints[c];
                return state.ColumnFirstClaimByPlayerIndex.TryGetValue(c, out var owner) && owner == pair.i ? pts.first : pts.later;
            });
            var colorBonus = p.CompletedColors.Count * 5;
            var jokerBonus = p.JokerMarksRemaining;
            var uncheckedStars = state.Board.Where(c => c.Starred && !p.CheckedCells.Contains(c.Id)).Count();
            var starPenalty = uncheckedStars * 2;
            var total = colPts + colorBonus + jokerBonus - starPenalty;
            result.Add(new { playerIndex = pair.i, player = p.Name, columns = colPts, colorBonus, jokerBonus, starPenalty, total });
        }
        return result;
    }

    private static CellColor ResolveColorFromCells(GameState state, List<string> ids)
    {
        var colors = state.Board.Where(c => ids.Contains(c.Id)).Select(c => c.Color).Distinct().ToList();
        return colors.Count == 1 ? colors[0] : throw new InvalidOperationException("Joker color must still resolve to one color.");
    }

    private static bool IsConnected(List<CellDef> cells)
    {
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
        return move.Any(c => existingCoords.Contains((c.X + 1, c.Y)) || existingCoords.Contains((c.X - 1, c.Y)) || existingCoords.Contains((c.X, c.Y + 1)) || existingCoords.Contains((c.X, c.Y - 1)));
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
            }
        }

        foreach (var color in Enum.GetValues<CellColor>())
        {
            if (p.CompletedColors.Contains(color)) continue;
            var allColor = state.Board.Where(c => c.Color == color).Select(c => c.Id);
            if (allColor.All(id => p.CheckedCells.Contains(id))) p.CompletedColors.Add(color);
        }
    }

    private static Dictionary<string, (int first, int later)> BuildColumnPoints()
    {
        var top = new[] { 5,3,3,3,2,2,2,1,2,2,2,3,3,3,5 };
        var low = new[] { 3,2,2,2,1,1,1,0,1,1,1,2,2,2,3 };
        var cols = "ABCDEFGHIJKLMNO".ToCharArray();
        return cols.Select((c, i) => new { c, i }).ToDictionary(x => x.c.ToString(), x => (top[x.i], low[x.i]));
    }

    private static List<CellDef> BuildTemplateBoard()
    {
        // Best-effort board mapped from reference photo (A-O x 8 rows)
        // G=Green, Y=Yellow, O=Orange, B=Blue, P=Pink/Purple
        var rows = new[]
        {
            "GGGYYYYGBBBOYYY",
            "OGGYYYYOPPBBOOY",
            "BGPPGYGOOPBOOGG",
            "BPOGOOBPPYOOOGG",
            "POOYYBBGOYOPPBB",
            "PBPPOOPPYOPOPPB",
            "YBPPPPPYOOPPBBO",
            "YYBBBBPYYYGGOOO"
        };

        var stars = new HashSet<(int x, int y)>
        {
            (0,2),(2,1),(4,1),(6,2),(7,0),(9,2),(11,0),(14,6),(13,7),(10,4),(8,6),(3,5),(5,3),(12,5)
        };

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
}
