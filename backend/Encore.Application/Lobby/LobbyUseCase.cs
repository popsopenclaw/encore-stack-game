using Encore.Application.Abstractions;
using Encore.Application.Contracts.Lobby;
using Encore.Domain.Models;
using Microsoft.Extensions.Configuration;
using LobbyEntity = Encore.Domain.Models.Lobby;

namespace Encore.Application.Lobby;

public class LobbyUseCase(ILobbyRepository repository, IConfiguration configuration) : ILobbyUseCase
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
        await CleanupStaleLobbies(cancellationToken);

        var lobby = await repository.GetByCodeAsync(code.Trim().ToUpperInvariant(), cancellationToken);
        if (lobby is null) return null;

        if (lobby.CreatedAt < StaleThreshold())
        {
            repository.RemoveLobby(lobby);
            await repository.SaveChangesAsync(cancellationToken);
            return null;
        }

        return ToDto(lobby);
    }

    public async Task<List<LobbyDto>> ListAsync(int limit = 20, CancellationToken cancellationToken = default)
    {
        await CleanupStaleLobbies(cancellationToken);
        var list = await repository.ListOpenAsync(limit, cancellationToken);
        return list.Where(l => l.CreatedAt >= StaleThreshold()).Select(ToDto).ToList();
    }

    public async Task<LobbyDto> UpdateAsync(Guid accountId, string code, UpdateLobbyRequest request, CancellationToken cancellationToken = default)
    {
        var lobby = await repository.GetByCodeAsync(code.Trim().ToUpperInvariant(), cancellationToken)
                    ?? throw new KeyNotFoundException("Lobby not found");

        if (lobby.HostAccountId != accountId)
            throw new UnauthorizedAccessException("Only host can update lobby settings");

        if (!string.IsNullOrWhiteSpace(request.Name))
            lobby.Name = request.Name.Trim();

        if (request.MaxPlayers.HasValue)
        {
            var next = request.MaxPlayers.Value;
            if (next < 1 || next > 6)
                throw new InvalidOperationException("Max players must be 1..6");
            if (next < lobby.Members.Count)
                throw new InvalidOperationException("Max players cannot be less than current member count");

            lobby.MaxPlayers = next;
        }

        await repository.SaveChangesAsync(cancellationToken);
        return ToDto(lobby);
    }

    public async Task LeaveAsync(Guid accountId, string code, CancellationToken cancellationToken = default)
    {
        var lobby = await repository.GetByCodeAsync(code.Trim().ToUpperInvariant(), cancellationToken)
                    ?? throw new KeyNotFoundException("Lobby not found");

        var member = lobby.Members.FirstOrDefault(m => m.AccountId == accountId);
        if (member is null) return;

        var wasHost = lobby.HostAccountId == accountId;

        repository.RemoveMember(member);

        var remainingMembers = lobby.Members.Where(m => m.AccountId != accountId).OrderBy(m => m.JoinedAt).ToList();

        if (remainingMembers.Count == 0)
        {
            repository.RemoveLobby(lobby);
        }
        else if (wasHost)
        {
            lobby.HostAccountId = remainingMembers[0].AccountId;
        }

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

    private DateTimeOffset StaleThreshold()
    {
        var hours = configuration.GetValue<int?>("Lobby:StaleHours") ?? 24;
        if (hours < 1) hours = 1;
        return DateTimeOffset.UtcNow.AddHours(-hours);
    }

    private async Task CleanupStaleLobbies(CancellationToken cancellationToken)
    {
        var stale = await repository.ListStaleAsync(StaleThreshold(), cancellationToken);
        if (stale.Count == 0) return;

        foreach (var lobby in stale)
            repository.RemoveLobby(lobby);

        await repository.SaveChangesAsync(cancellationToken);
    }

    private static string GenerateCode()
        => Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();
}
