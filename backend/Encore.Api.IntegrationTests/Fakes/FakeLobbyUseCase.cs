using Encore.Application.Contracts.Lobby;
using Encore.Application.Lobby;

namespace Encore.Api.IntegrationTests.Fakes;

public class FakeLobbyUseCase : ILobbyUseCase
{
    private static readonly Dictionary<string, LobbyDto> _store = new(StringComparer.OrdinalIgnoreCase);

    public Task<LobbyDto> CreateAsync(Guid accountId, CreateLobbyRequest request, CancellationToken cancellationToken = default)
    {
        var code = "ABC123";
        var dto = new LobbyDto(Guid.NewGuid(), code, request.Name, request.MaxPlayers, request.HostDisplayName,
            [new LobbyMemberDto(accountId, request.HostDisplayName, DateTimeOffset.UtcNow)]);
        _store[code] = dto;
        return Task.FromResult(dto);
    }

    public Task<LobbyDto> JoinAsync(Guid accountId, JoinLobbyRequest request, CancellationToken cancellationToken = default)
    {
        if (!_store.TryGetValue(request.Code, out var lobby))
            throw new KeyNotFoundException();

        var members = lobby.Members.ToList();
        members.Add(new LobbyMemberDto(accountId, request.DisplayName, DateTimeOffset.UtcNow));
        var updated = lobby with { Members = members };
        _store[lobby.Code] = updated;
        return Task.FromResult(updated);
    }

    public Task<LobbyDto?> GetAsync(string code, CancellationToken cancellationToken = default)
        => Task.FromResult(_store.TryGetValue(code, out var l) ? l : null);

    public Task<List<LobbyDto>> ListAsync(int limit = 20, CancellationToken cancellationToken = default)
        => Task.FromResult(_store.Values.Take(limit).ToList());

    public Task LeaveAsync(Guid accountId, string code, CancellationToken cancellationToken = default)
    {
        if (_store.TryGetValue(code, out var lobby))
        {
            var members = lobby.Members.Where(m => m.AccountId != accountId).ToList();
            _store[code] = lobby with { Members = members };
        }
        return Task.CompletedTask;
    }
}
