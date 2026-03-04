using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Encore.Api.Hubs;
using Encore.Application.Contracts.Lobby;
using Microsoft.AspNetCore.SignalR;
using StackExchange.Redis;

namespace Encore.Api.Services;

public class LobbyRealtimeNotifier(IHubContext<LobbyHub> hub, IServiceProvider services, IConfiguration configuration)
{
    private readonly IDatabase? _db = services.GetService<IConnectionMultiplexer>()?.GetDatabase();

    public async Task LobbyUpdatedAsync(LobbyDto lobby)
    {
        var code = lobby.Code.Trim().ToUpperInvariant();
        var payload = JsonSerializer.Serialize(lobby);
        var hash = Sha256(payload);

        // If redis is unavailable (e.g., certain test hosts), skip dedupe but still notify.
        if (_db is null)
        {
            await hub.Clients.Group(LobbyHub.GroupName(lobby.Code)).SendAsync("lobbyUpdated", lobby);
            return;
        }

        var key = $"lobby:notify:last:{code}";
        var ttlSeconds = configuration.GetValue<int?>("Lobby:NotifyDedupeTtlSeconds") ?? 300;
        if (ttlSeconds < 30) ttlSeconds = 30;

        var previous = await _db.StringGetAsync(key);
        if (previous.HasValue && previous.ToString() == hash)
            return;

        await hub.Clients.Group(LobbyHub.GroupName(lobby.Code)).SendAsync("lobbyUpdated", lobby);
        await _db.StringSetAsync(key, hash, TimeSpan.FromSeconds(ttlSeconds));
    }

    private static string Sha256(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes);
    }
}
