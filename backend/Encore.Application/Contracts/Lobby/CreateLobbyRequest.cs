namespace Encore.Application.Contracts.Lobby;

public record CreateLobbyRequest(string Name, int MaxPlayers, string HostDisplayName);