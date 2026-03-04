namespace Encore.Application.Contracts.Lobby;

public record UpdateLobbyRequest(string? Name, int? MaxPlayers);
