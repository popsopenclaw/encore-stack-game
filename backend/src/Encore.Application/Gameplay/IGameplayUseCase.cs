using Encore.Api.Domain;

namespace Encore.Application.Gameplay;

public interface IGameplayUseCase
{
    Task<GameState> StartAsync(StartGameRequest request, CancellationToken cancellationToken = default);
    Task<GameState?> GetAsync(string sessionId, CancellationToken cancellationToken = default);
    Task<DiceRoll> RollAsync(string sessionId, CancellationToken cancellationToken = default);
    Task<GameState> ActiveSelectAsync(string sessionId, ActiveSelectionRequest request, CancellationToken cancellationToken = default);
    Task<DiceRoll> GetAvailableDiceAsync(string sessionId, int playerIndex, CancellationToken cancellationToken = default);
    Task<GameState> PlayerActionAsync(string sessionId, PlayerActionRequest request, CancellationToken cancellationToken = default);
    Task<GameState> EnableEncoreAsync(string sessionId, CancellationToken cancellationToken = default);
    Task<List<object>?> ScoreAsync(string sessionId, CancellationToken cancellationToken = default);
    Task<List<TurnEvent>?> EventsAsync(string sessionId, CancellationToken cancellationToken = default);
    Task<GameState> LegacyMoveAsync(string sessionId, MoveRequest move, CancellationToken cancellationToken = default);
}
