using System.Text.Json;
using Encore.Domain.Models;
using StackExchange.Redis;

namespace Encore.Infrastructure.Services;

public class GameSessionService(IConnectionMultiplexer redis) : IGameStateStore
{
    private readonly IDatabase _db = redis.GetDatabase();

    // Generic state store (for reusable future board games)
    public async Task SaveStateAsync(string gameKey, string sessionId, string stateJson, TimeSpan? ttl = null)
        => await _db.StringSetAsync(Key(gameKey, sessionId), stateJson, ttl ?? TimeSpan.FromDays(7));

    public async Task<T?> GetStateAsync<T>(string gameKey, string sessionId)
    {
        var value = await _db.StringGetAsync(Key(gameKey, sessionId));
        if (!value.HasValue) return default;
        return JsonSerializer.Deserialize<T>(value.ToString());
    }

    // Backward-compatible helpers for Encore
    public Task SaveStateAsync(string sessionId, string stateJson)
        => SaveStateAsync("encore", sessionId, stateJson);

    public Task<T?> GetStateAsync<T>(string sessionId)
        => GetStateAsync<T>("encore", sessionId);

    public async Task<GameSession> CreateAsync(Guid ownerAccountId, string? name, string? initialStateJson)
    {
        var session = new GameSession
        {
            OwnerAccountId = ownerAccountId,
            Name = string.IsNullOrWhiteSpace(name) ? "New Session" : name.Trim(),
            StateJson = string.IsNullOrWhiteSpace(initialStateJson) ? "{}" : initialStateJson
        };

        await _db.StringSetAsync(Key("encore", session.Id), JsonSerializer.Serialize(session), TimeSpan.FromDays(7));
        return session;
    }

    public async Task<GameSession?> GetAsync(string sessionId)
    {
        var value = await _db.StringGetAsync(Key("encore", sessionId));
        if (!value.HasValue) return null;
        return JsonSerializer.Deserialize<GameSession>(value.ToString());
    }

    public async Task<GameSession?> UpdateStateAsync(string sessionId, string stateJson)
    {
        var session = await GetAsync(sessionId);
        if (session is null) return null;

        session.StateJson = stateJson;
        session.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.StringSetAsync(Key("encore", session.Id), JsonSerializer.Serialize(session), TimeSpan.FromDays(7));
        return session;
    }

    private static string Key(string gameKey, string sessionId) => $"game:{gameKey}:session:{sessionId}";
}
