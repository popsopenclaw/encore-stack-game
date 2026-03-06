using Encore.Application.Contracts.Lobby;
using Encore.Application.Lobby;

namespace Encore.Api.IntegrationTests.Fakes;

public class FakeLobbyUseCase : ILobbyUseCase
{
    private readonly Dictionary<string, LobbyDto> _store = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<Guid, string> _playerNames = new();

    public Task<LobbyDto> CreateAsync(Guid accountId, CreateLobbyRequest request, CancellationToken cancellationToken = default)
    {
        var code = Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();
        var hostName = GetPlayerName(accountId);
        var dto = new LobbyDto(Guid.NewGuid(), code, request.Name, request.MaxPlayers, accountId, hostName,
            [new LobbyMemberDto(accountId, hostName, DateTimeOffset.UtcNow)],
            null,
            false);
        _store[code] = dto;
        return Task.FromResult(dto);
    }

    public Task<LobbyDto> JoinAsync(Guid accountId, JoinLobbyRequest request, CancellationToken cancellationToken = default)
    {
        if (!_store.TryGetValue(request.Code, out var lobby))
            throw new KeyNotFoundException();

        var members = lobby.Members.ToList();
        members.Add(new LobbyMemberDto(accountId, GetPlayerName(accountId), DateTimeOffset.UtcNow));
        var updated = lobby with { Members = members };
        _store[lobby.Code] = updated;
        return Task.FromResult(updated);
    }

    public Task<LobbyDto?> GetAsync(string code, CancellationToken cancellationToken = default)
        => Task.FromResult(_store.TryGetValue(code, out var l) ? l : null);

    public Task<List<LobbyDto>> ListAsync(int limit = 20, CancellationToken cancellationToken = default)
        => Task.FromResult(_store.Values.Take(limit).ToList());

    public Task<LobbyDto> UpdateAsync(Guid accountId, string code, UpdateLobbyRequest request, CancellationToken cancellationToken = default)
    {
        if (!_store.TryGetValue(code, out var lobby))
            throw new KeyNotFoundException();

        if (lobby.Members.FirstOrDefault()?.AccountId != accountId)
            throw new UnauthorizedAccessException("Only host can update lobby settings");

        var updated = lobby with
        {
            Name = string.IsNullOrWhiteSpace(request.Name) ? lobby.Name : request.Name.Trim(),
            MaxPlayers = request.MaxPlayers ?? lobby.MaxPlayers
        };
        _store[code] = updated;
        return Task.FromResult(updated);
    }

    public Task<string> StartMatchAsync(Guid accountId, string code, StartLobbyMatchRequest request, CancellationToken cancellationToken = default)
    {
        if (!_store.TryGetValue(code, out var lobby))
            throw new KeyNotFoundException();

        if (lobby.Members.FirstOrDefault()?.AccountId != accountId)
            throw new UnauthorizedAccessException("Only host can start a match");

        if (!string.IsNullOrWhiteSpace(lobby.ActiveSessionId))
            return Task.FromResult(lobby.ActiveSessionId!);

        const string sessionId = "test-session";
        _store[code] = lobby with { ActiveSessionId = sessionId, HasActiveGame = true };
        return Task.FromResult(sessionId);
    }

    public Task LeaveAsync(Guid accountId, string code, CancellationToken cancellationToken = default)
    {
        if (_store.TryGetValue(code, out var lobby))
        {
            var members = lobby.Members.Where(m => m.AccountId != accountId).ToList();
            _store[code] = lobby with { Members = members };
        }
        return Task.CompletedTask;
    }

    private string GetPlayerName(Guid accountId)
    {
        if (_playerNames.TryGetValue(accountId, out var playerName))
            return playerName;

        playerName = $"player-{_playerNames.Count + 1}";
        _playerNames[accountId] = playerName;
        return playerName;
    }
}
