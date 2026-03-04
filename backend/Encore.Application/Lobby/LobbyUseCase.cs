using Encore.Application.Abstractions;
using Encore.Application.Contracts.Lobby;
using Encore.Domain.Models;
using LobbyEntity = Encore.Domain.Models.Lobby;

namespace Encore.Application.Lobby;

public class LobbyUseCase(ILobbyRepository repository) : ILobbyUseCase
{
    public async Task<LobbyDto> CreateAsync(Guid accountId, CreateLobbyRequest request, CancellationToken cancellationToken = default)
    {
        if (request.MaxPlayers is < 1 or > 6) throw new InvalidOperationException("Max players must be 1..6");
        var code = GenerateCode();

        var lobby = new LobbyEntity
        {
            Code = code,
            Name = request.Name.Trim(),
            HostAccountId = accountId,
            MaxPlayers = request.MaxPlayers,
            Members =
            [
                new LobbyMember
                {
                    AccountId = accountId,
                    DisplayName = request.HostDisplayName.Trim()
                }
            ]
        };

        await repository.CreateAsync(lobby, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
        return ToDto(lobby);
    }

    public async Task<LobbyDto> JoinAsync(Guid accountId, JoinLobbyRequest request, CancellationToken cancellationToken = default)
    {
        var lobby = await repository.GetByCodeAsync(request.Code.Trim().ToUpperInvariant(), cancellationToken)
                    ?? throw new KeyNotFoundException("Lobby not found");

        if (lobby.Members.Any(m => m.AccountId == accountId))
            return ToDto(lobby);

        if (lobby.Members.Count >= lobby.MaxPlayers)
            throw new InvalidOperationException("Lobby is full");

        lobby.Members.Add(new LobbyMember
        {
            AccountId = accountId,
            DisplayName = request.DisplayName.Trim(),
            LobbyId = lobby.Id
        });

        await repository.SaveChangesAsync(cancellationToken);
        return ToDto(lobby);
    }

    public async Task<LobbyDto?> GetAsync(string code, CancellationToken cancellationToken = default)
    {
        var lobby = await repository.GetByCodeAsync(code.Trim().ToUpperInvariant(), cancellationToken);
        return lobby is null ? null : ToDto(lobby);
    }

    public async Task<List<LobbyDto>> ListAsync(int limit = 20, CancellationToken cancellationToken = default)
    {
        var list = await repository.ListOpenAsync(limit, cancellationToken);
        return list.Select(ToDto).ToList();
    }

    public async Task LeaveAsync(Guid accountId, string code, CancellationToken cancellationToken = default)
    {
        var lobby = await repository.GetByCodeAsync(code.Trim().ToUpperInvariant(), cancellationToken)
                    ?? throw new KeyNotFoundException("Lobby not found");

        var member = lobby.Members.FirstOrDefault(m => m.AccountId == accountId);
        if (member is null) return;

        repository.RemoveMember(member);
        await repository.SaveChangesAsync(cancellationToken);
    }

    private static LobbyDto ToDto(LobbyEntity lobby)
        => new(
            lobby.Id,
            lobby.Code,
            lobby.Name,
            lobby.MaxPlayers,
            lobby.Members.FirstOrDefault(m => m.AccountId == lobby.HostAccountId)?.DisplayName ?? "Host",
            lobby.Members.Select(m => new LobbyMemberDto(m.AccountId, m.DisplayName, m.JoinedAt)).ToList()
        );

    private static string GenerateCode()
        => Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();
}
