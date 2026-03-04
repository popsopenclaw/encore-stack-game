namespace Encore.Application.Contracts.Lobby;

public record LobbyDto(Guid Id, string Code, string Name, int MaxPlayers, string HostDisplayName, List<LobbyMemberDto> Members);

public record LobbyMemberDto(Guid AccountId, string DisplayName, DateTimeOffset JoinedAt);