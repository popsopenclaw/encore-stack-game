using Encore.Domain;

namespace Encore.Application.Gameplay;

public interface IGameplayUseCase
{
    Task<GameState?> GetAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default);
    Task<DiceRoll> RollAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default);
    Task<GameState> ActiveSelectAsync(Guid accountId, string sessionId, ActiveSelectionRequest request, CancellationToken cancellationToken = default);
    Task<DiceRoll> GetAvailableDiceAsync(Guid accountId, string sessionId, int playerIndex, CancellationToken cancellationToken = default);
    Task<GameState> PlayerActionAsync(Guid accountId, string sessionId, PlayerActionRequest request, CancellationToken cancellationToken = default);
    Task<GameState> EnableEncoreAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default);
    Task<List<object>?> ScoreAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default);
    Task<List<TurnEvent>?> EventsAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default);
}
