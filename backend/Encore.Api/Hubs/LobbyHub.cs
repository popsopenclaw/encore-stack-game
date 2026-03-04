using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Encore.Api.Hubs;

[Authorize]
public class LobbyHub : Hub
{
    public Task JoinLobby(string code)
        => Groups.AddToGroupAsync(Context.ConnectionId, GroupName(code));

    public Task LeaveLobby(string code)
        => Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(code));

    public static string GroupName(string code) => $"lobby:{code.Trim().ToUpperInvariant()}";
}
