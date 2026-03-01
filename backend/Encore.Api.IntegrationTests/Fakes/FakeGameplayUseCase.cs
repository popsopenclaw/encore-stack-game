using Encore.Application.Gameplay;
using Encore.Domain;

namespace Encore.Api.IntegrationTests.Fakes;

public class FakeGameplayUseCase : IGameplayUseCase
{
    public Task<GameState> StartAsync(StartGameRequest request, CancellationToken cancellationToken = default)
    {
        var state = new GameState
        {
            SessionId = "test-session",
            Players = request.PlayerNames.Select(n => new PlayerState { Name = n }).ToList(),
            Board = []
        };
        return Task.FromResult(state);
    }

    public Task<GameState?> GetAsync(string sessionId, CancellationToken cancellationToken = default)
        => Task.FromResult<GameState?>(new GameState { SessionId = sessionId, Board = [] });

    public Task<DiceRoll> RollAsync(string sessionId, CancellationToken cancellationToken = default)
        => Task.FromResult(new DiceRoll([ColorDieFace.Blue], [NumberDieFace.Three]));

    public Task<GameState> ActiveSelectAsync(string sessionId, ActiveSelectionRequest request, CancellationToken cancellationToken = default)
        => Task.FromResult(new GameState { SessionId = sessionId, Board = [] });

    public Task<DiceRoll> GetAvailableDiceAsync(string sessionId, int playerIndex, CancellationToken cancellationToken = default)
        => Task.FromResult(new DiceRoll([ColorDieFace.Green], [NumberDieFace.One]));

    public Task<GameState> PlayerActionAsync(string sessionId, PlayerActionRequest request, CancellationToken cancellationToken = default)
        => Task.FromResult(new GameState { SessionId = sessionId, Board = [] });

    public Task<GameState> EnableEncoreAsync(string sessionId, CancellationToken cancellationToken = default)
        => Task.FromResult(new GameState { SessionId = sessionId, Board = [] });

    public Task<List<object>?> ScoreAsync(string sessionId, CancellationToken cancellationToken = default)
        => Task.FromResult<List<object>?>([new { player = "tester", total = 0 }]);

    public Task<List<TurnEvent>?> EventsAsync(string sessionId, CancellationToken cancellationToken = default)
        => Task.FromResult<List<TurnEvent>?>([new TurnEvent { Turn = 1, Type = "roll" }]);

    public Task<GameState> LegacyMoveAsync(string sessionId, MoveRequest move, CancellationToken cancellationToken = default)
        => Task.FromResult(new GameState { SessionId = sessionId, Board = [] });
}
