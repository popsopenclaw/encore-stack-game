using Encore.Domain;
using Encore.Infrastructure.Services;
using Encore.Application.Abstractions;

namespace Encore.Infrastructure.Adapters;

public class GameplayRepositoryAdapter(GameSessionService service) : IGameplayRepository
{
    public Task SaveAsync(string sessionId, GameState state)
        => service.SaveStateAsync(sessionId, System.Text.Json.JsonSerializer.Serialize(state));

    public Task<GameState?> GetAsync(string sessionId)
        => service.GetStateAsync<GameState>(sessionId);
}
