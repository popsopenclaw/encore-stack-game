namespace Encore.Application.Contracts.Lobby;

public record LobbyDto(
    Guid Id,
    string Code,
    string Name,
    int MaxPlayers,
    Guid HostAccountId,
    string HostDisplayName,
    List<LobbyMemberDto> Members,
    string? ActiveSessionId,
    bool HasActiveGame);

public record LobbyMemberDto(Guid AccountId, string DisplayName, DateTimeOffset JoinedAt);
