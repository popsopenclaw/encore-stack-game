using Encore.Api.Hubs;
using Encore.Application.Contracts.Lobby;
using Microsoft.AspNetCore.SignalR;

namespace Encore.Api.Services;

public class LobbyRealtimeNotifier(IHubContext<LobbyHub> hub)
{
    public Task LobbyUpdatedAsync(LobbyDto lobby)
        => hub.Clients.Group(LobbyHub.GroupName(lobby.Code)).SendAsync("lobbyUpdated", lobby);
}
