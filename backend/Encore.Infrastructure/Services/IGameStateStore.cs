namespace Encore.Infrastructure.Services;

public interface IGameStateStore
{
    Task SaveStateAsync(string gameKey, string sessionId, string stateJson, TimeSpan? ttl = null);
    Task<T?> GetStateAsync<T>(string gameKey, string sessionId);
}
