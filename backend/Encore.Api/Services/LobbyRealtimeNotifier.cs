using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Encore.Api.Hubs;
using Encore.Application.Contracts.Lobby;
using Microsoft.AspNetCore.SignalR;
using StackExchange.Redis;

namespace Encore.Api.Services;

public class LobbyRealtimeNotifier(IHubContext<LobbyHub> hub, IServiceProvider services, IConfiguration configuration, ILogger<LobbyRealtimeNotifier> logger)
{
    public async Task LobbyUpdatedAsync(LobbyDto lobby)
    {
        var code = lobby.Code.Trim().ToUpperInvariant();
        var payload = JsonSerializer.Serialize(lobby);
        var hash = Sha256(payload);

        IDatabase? db = null;
        try
        {
            db = services.GetService<IConnectionMultiplexer>()?.GetDatabase();
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "Realtime dedupe cache unavailable; proceeding without dedupe for lobby {Code}", code);
        }

        // If redis is unavailable (e.g., CI/integration hosts), skip dedupe but still notify.
        if (db is null)
        {
            await hub.Clients.Group(LobbyHub.GroupName(lobby.Code)).SendAsync("lobbyUpdated", lobby);
            return;
        }

        var key = $"lobby:notify:last:{code}";
        var ttlSeconds = configuration.GetValue<int?>("Lobby:NotifyDedupeTtlSeconds") ?? 300;
        if (ttlSeconds < 30) ttlSeconds = 30;

        var previous = await db.StringGetAsync(key);
        if (previous.HasValue && previous.ToString() == hash)
            return;

        await hub.Clients.Group(LobbyHub.GroupName(lobby.Code)).SendAsync("lobbyUpdated", lobby);
        await db.StringSetAsync(key, hash, TimeSpan.FromSeconds(ttlSeconds));
    }

    private static string Sha256(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes);
    }
}
