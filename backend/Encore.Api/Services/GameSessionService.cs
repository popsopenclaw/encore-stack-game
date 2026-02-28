using System.Text.Json;
using Encore.Api.Models;
using StackExchange.Redis;

namespace Encore.Api.Services;

public class GameSessionService(IConnectionMultiplexer redis)
{
    private readonly IDatabase _db = redis.GetDatabase();



    public async Task SaveStateAsync(string sessionId, string stateJson)
        => await _db.StringSetAsync(Key(sessionId), stateJson, TimeSpan.FromDays(7));

    public async Task<T?> GetStateAsync<T>(string sessionId)
    {
        var value = await _db.StringGetAsync(Key(sessionId));
        if (!value.HasValue) return default;
        return System.Text.Json.JsonSerializer.Deserialize<T>(value!);
    }
    public async Task<GameSession> CreateAsync(Guid ownerAccountId, string? name, string? initialStateJson)
    {
        var session = new GameSession
        {
            OwnerAccountId = ownerAccountId,
            Name = string.IsNullOrWhiteSpace(name) ? "New Session" : name.Trim(),
            StateJson = string.IsNullOrWhiteSpace(initialStateJson) ? "{}" : initialStateJson
        };

        var payload = JsonSerializer.Serialize(session);
        await _db.StringSetAsync(Key(session.Id), payload, TimeSpan.FromDays(7));
        return session;
    }

    public async Task<GameSession?> GetAsync(string sessionId)
    {
        var value = await _db.StringGetAsync(Key(sessionId));
        if (!value.HasValue) return null;
        return JsonSerializer.Deserialize<GameSession>(value!);
    }

    public async Task<GameSession?> UpdateStateAsync(string sessionId, string stateJson)
    {
        var session = await GetAsync(sessionId);
        if (session is null) return null;

        session.StateJson = stateJson;
        session.UpdatedAt = DateTimeOffset.UtcNow;

        await _db.StringSetAsync(Key(session.Id), JsonSerializer.Serialize(session), TimeSpan.FromDays(7));
        return session;
    }

    private static string Key(string sessionId) => $"encore:session:{sessionId}";
}
