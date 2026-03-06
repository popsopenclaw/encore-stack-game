using Encore.Application.Abstractions;
using Encore.Application.Contracts.Lobby;
using Encore.Domain.Models;
using Microsoft.Extensions.Configuration;
using LobbyEntity = Encore.Domain.Models.Lobby;

namespace Encore.Application.Lobby;

public class LobbyUseCase(
    ILobbyRepository repository,
    IAccountRepository accountRepository,
    IConfiguration configuration,
    IGameplayRepository gameplayRepository,
    IGameRules rules) : ILobbyUseCase
{
    public async Task<LobbyDto> CreateAsync(Guid accountId, CreateLobbyRequest request, CancellationToken cancellationToken = default)
    {
        if (request.MaxPlayers is < 1 or > 6) throw new InvalidOperationException("Max players must be 1..6");
        var account = await accountRepository.GetByIdAsync(accountId, cancellationToken)
            ?? throw new InvalidSessionException("Session is invalid.");
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
                    DisplayName = account.PlayerName
                }
            ]
        };

        await repository.CreateAsync(lobby, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
        return await ToDtoAsync(lobby, cancellationToken);
    }

    public async Task<LobbyDto> JoinAsync(Guid accountId, JoinLobbyRequest request, CancellationToken cancellationToken = default)
    {
        var lobby = await repository.GetByCodeAsync(request.Code.Trim().ToUpperInvariant(), cancellationToken)
                    ?? throw new KeyNotFoundException("Lobby not found");
        var account = await accountRepository.GetByIdAsync(accountId, cancellationToken)
            ?? throw new InvalidSessionException("Session is invalid.");

        if (lobby.Members.Any(m => m.AccountId == accountId))
            return await ToDtoAsync(lobby, cancellationToken);

        if (lobby.Members.Count >= lobby.MaxPlayers)
            throw new InvalidOperationException("Lobby is full");

        lobby.Members.Add(new LobbyMember
        {
            AccountId = accountId,
            DisplayName = account.PlayerName,
            LobbyId = lobby.Id
        });

        await repository.SaveChangesAsync(cancellationToken);
        return await ToDtoAsync(lobby, cancellationToken);
    }

    public async Task<LobbyDto?> GetAsync(string code, CancellationToken cancellationToken = default)
    {
        var lobby = await repository.GetByCodeAsync(code.Trim().ToUpperInvariant(), cancellationToken);
        if (lobby is null) return null;

        if (lobby.CreatedAt < StaleThreshold())
            return null;

        return await ToDtoAsync(lobby, cancellationToken);
    }

    public async Task<List<LobbyDto>> ListAsync(int limit = 20, CancellationToken cancellationToken = default)
    {
        var list = await repository.ListOpenAsync(limit, cancellationToken);
        var active = list.Where(l => l.CreatedAt >= StaleThreshold()).ToList();
        var namesByAccountId = await LoadPlayerNamesAsync(
            active.SelectMany(l => l.Members.Select(m => m.AccountId)).Distinct().ToList(),
            cancellationToken);
        return active.Select(l => ToDto(l, namesByAccountId)).ToList();
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
        return await ToDtoAsync(lobby, cancellationToken);
    }

    public async Task<string> StartMatchAsync(Guid accountId, string code, StartLobbyMatchRequest request, CancellationToken cancellationToken = default)
    {
        var lobby = await repository.GetByCodeAsync(code.Trim().ToUpperInvariant(), cancellationToken)
                    ?? throw new KeyNotFoundException("Lobby not found");

        if (lobby.HostAccountId != accountId)
            throw new UnauthorizedAccessException("Only host can start a match");

        if (!string.IsNullOrWhiteSpace(lobby.ActiveSessionId))
            return lobby.ActiveSessionId;

        var namesByAccountId = await LoadPlayerNamesAsync(
            lobby.Members.Select(m => m.AccountId).Distinct().ToList(),
            cancellationToken);
        var names = lobby.Members
            .Select(m => namesByAccountId.TryGetValue(m.AccountId, out var playerName) && !string.IsNullOrWhiteSpace(playerName)
                ? playerName
                : string.IsNullOrWhiteSpace(m.DisplayName) ? "Player" : m.DisplayName)
            .ToList();
        var state = rules.NewGame(names);
        await gameplayRepository.SaveAsync(state.SessionId, state);
        lobby.ActiveSessionId = state.SessionId;
        await repository.SaveChangesAsync(cancellationToken);
        return state.SessionId;
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

    private async Task<LobbyDto> ToDtoAsync(LobbyEntity lobby, CancellationToken cancellationToken)
    {
        var namesByAccountId = await LoadPlayerNamesAsync(
            lobby.Members.Select(m => m.AccountId).Distinct().ToList(),
            cancellationToken);
        return ToDto(lobby, namesByAccountId);
    }

    private static LobbyDto ToDto(LobbyEntity lobby, IReadOnlyDictionary<Guid, string> namesByAccountId)
        => new(
            lobby.Id,
            lobby.Code,
            lobby.Name,
            lobby.MaxPlayers,
            lobby.HostAccountId,
            namesByAccountId.TryGetValue(lobby.HostAccountId, out var hostPlayerName) ? hostPlayerName : "Host",
            lobby.Members.Select(m => new LobbyMemberDto(
                m.AccountId,
                namesByAccountId.TryGetValue(m.AccountId, out var playerName) && !string.IsNullOrWhiteSpace(playerName)
                    ? playerName
                    : m.DisplayName,
                m.JoinedAt)).ToList(),
            lobby.ActiveSessionId,
            !string.IsNullOrWhiteSpace(lobby.ActiveSessionId)
        );

    private async Task<Dictionary<Guid, string>> LoadPlayerNamesAsync(
        IReadOnlyCollection<Guid> accountIds,
        CancellationToken cancellationToken)
    {
        if (accountIds.Count == 0)
            return [];

        var accounts = await accountRepository.GetByIdsAsync(accountIds, cancellationToken);
        return accounts
            .Where(a => !string.IsNullOrWhiteSpace(a.PlayerName))
            .ToDictionary(a => a.Id, a => a.PlayerName);
    }

    private DateTimeOffset StaleThreshold()
    {
        var hours = configuration.GetValue<int?>("Lobby:StaleHours") ?? 24;
        if (hours < 1) hours = 1;
        return DateTimeOffset.UtcNow.AddHours(-hours);
    }

    private static string GenerateCode()
        => Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();
}
