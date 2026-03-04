using System.Collections.Concurrent;
using System.Text.Json;
using Encore.Api.Hubs;
using Encore.Application.Contracts.Lobby;
using Microsoft.AspNetCore.SignalR;

namespace Encore.Api.Services;

public class LobbyRealtimeNotifier(IHubContext<LobbyHub> hub)
{
    private static readonly ConcurrentDictionary<string, string> LastPayloadByLobby = new(StringComparer.OrdinalIgnoreCase);

    public async Task LobbyUpdatedAsync(LobbyDto lobby)
    {
        var key = lobby.Code.Trim().ToUpperInvariant();
        var payload = JsonSerializer.Serialize(lobby);

        if (LastPayloadByLobby.TryGetValue(key, out var previous) && string.Equals(previous, payload, StringComparison.Ordinal))
            return;

        LastPayloadByLobby[key] = payload;
        await hub.Clients.Group(LobbyHub.GroupName(lobby.Code)).SendAsync("lobbyUpdated", lobby);
    }
}
