using Encore.Domain;

namespace Encore.Application.Abstractions;

public interface IGameplayRepository
{
    Task SaveAsync(string sessionId, GameState state);
    Task<GameState?> GetAsync(string sessionId);
}
