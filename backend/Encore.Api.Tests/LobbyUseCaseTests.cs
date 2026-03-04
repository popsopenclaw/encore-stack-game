using Encore.Application.Abstractions;
using Encore.Application.Contracts.Lobby;
using Encore.Application.Lobby;
using Encore.Domain;
using Encore.Domain.Models;
using Microsoft.Extensions.Configuration;
using LobbyEntity = Encore.Domain.Models.Lobby;

namespace Encore.Api.Tests;

public class LobbyUseCaseTests
{
    [Fact]
    public async Task HostLeaves_TransfersHostToOldestRemainingMember()
    {
        var repo = new FakeLobbyRepository();
        var useCase = CreateUseCase(repo, staleHours: 24);

        var hostId = Guid.NewGuid();
        var otherId = Guid.NewGuid();

        var created = await useCase.CreateAsync(hostId, new CreateLobbyRequest("L", 4, "Host"));
        await useCase.JoinAsync(otherId, new JoinLobbyRequest(created.Code, "P2"));

        await useCase.LeaveAsync(hostId, created.Code);

        var lobby = await repo.GetByCodeAsync(created.Code);
        Assert.NotNull(lobby);
        Assert.Equal(otherId, lobby!.HostAccountId);
    }

    [Fact]
    public async Task LastMemberLeaves_RemovesLobby()
    {
        var repo = new FakeLobbyRepository();
        var useCase = CreateUseCase(repo, staleHours: 24);

        var hostId = Guid.NewGuid();
        var created = await useCase.CreateAsync(hostId, new CreateLobbyRequest("L", 4, "Host"));

        await useCase.LeaveAsync(hostId, created.Code);

        var lobby = await repo.GetByCodeAsync(created.Code);
        Assert.Null(lobby);
    }

    [Fact]
    public async Task NonHostCannotUpdateLobby()
    {
        var repo = new FakeLobbyRepository();
        var useCase = CreateUseCase(repo, staleHours: 24);

        var hostId = Guid.NewGuid();
        var userId = Guid.NewGuid();

        var created = await useCase.CreateAsync(hostId, new CreateLobbyRequest("L", 4, "Host"));
        await useCase.JoinAsync(userId, new JoinLobbyRequest(created.Code, "User"));

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            useCase.UpdateAsync(userId, created.Code, new UpdateLobbyRequest("Nope", 4)));
    }

    [Fact]
    public async Task HostCanUpdateLobbySettings()
    {
        var repo = new FakeLobbyRepository();
        var useCase = CreateUseCase(repo, staleHours: 24);

        var hostId = Guid.NewGuid();
        var created = await useCase.CreateAsync(hostId, new CreateLobbyRequest("L", 4, "Host"));

        var updated = await useCase.UpdateAsync(hostId, created.Code, new UpdateLobbyRequest("Renamed", 5));

        Assert.Equal("Renamed", updated.Name);
        Assert.Equal(5, updated.MaxPlayers);
    }


    [Fact]
    public async Task StaleLobbiesAreNotListed_AndRemainForAsyncCleanup()
    {
        var repo = new FakeLobbyRepository();
        var useCase = CreateUseCase(repo, staleHours: 1);

        var hostId = Guid.NewGuid();
        var created = await useCase.CreateAsync(hostId, new CreateLobbyRequest("L", 4, "Host"));

        // force stale
        var lobby = await repo.GetByCodeAsync(created.Code);
        lobby!.CreatedAt = DateTimeOffset.UtcNow.AddHours(-2);

        var list = await useCase.ListAsync();
        Assert.DoesNotContain(list, l => l.Code == created.Code);

        var stillThere = await repo.GetByCodeAsync(created.Code);
        Assert.NotNull(stillThere);
    }

    private static IConfiguration BuildConfig(int staleHours)
        => new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Lobby:StaleHours"] = staleHours.ToString()
        }).Build();


    [Fact]
    public async Task NonHostCannotStartMatch()
    {
        var repo = new FakeLobbyRepository();
        var useCase = CreateUseCase(repo, staleHours: 24);

        var hostId = Guid.NewGuid();
        var userId = Guid.NewGuid();

        var created = await useCase.CreateAsync(hostId, new CreateLobbyRequest("L", 4, "Host"));
        await useCase.JoinAsync(userId, new JoinLobbyRequest(created.Code, "User"));

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            useCase.StartMatchAsync(userId, created.Code, new StartLobbyMatchRequest("Game")));
    }

    [Fact]
    public async Task HostCanStartMatch()
    {
        var repo = new FakeLobbyRepository();
        var useCase = CreateUseCase(repo, staleHours: 24);

        var hostId = Guid.NewGuid();
        var created = await useCase.CreateAsync(hostId, new CreateLobbyRequest("L", 4, "Host"));

        var sessionId = await useCase.StartMatchAsync(hostId, created.Code, new StartLobbyMatchRequest("Game"));
        Assert.False(string.IsNullOrWhiteSpace(sessionId));
    }

    private static LobbyUseCase CreateUseCase(FakeLobbyRepository repo, int staleHours)
        => new(repo, BuildConfig(staleHours), new FakeGameplayRepository(), new FakeGameRules());

    private class FakeGameplayRepository : IGameplayRepository
    {
        public Task SaveAsync(string sessionId, GameState state) => Task.CompletedTask;
        public Task<GameState?> GetAsync(string sessionId) => Task.FromResult<GameState?>(null);
    }

    private class FakeGameRules : IGameRules
    {
        public GameState NewGame(List<string> playerNames)
            => new GameState { SessionId = Guid.NewGuid().ToString("N"), Players = playerNames.Select(n => new PlayerState { Name = n }).ToList(), Board = [] };

        public void RollForTurn(GameState state) { }
        public void ActivePlayerSelect(GameState state, ActiveSelectionRequest request) { }
        public DiceRoll GetAvailableDiceForPlayer(GameState state, int playerIndex)
            => new([ColorDieFace.Blue], [NumberDieFace.One]);
        public void ResolvePlayerAction(GameState state, PlayerActionRequest request) { }
        public void EnableEncore(GameState state) { }
        public List<object> CalculateScores(GameState state) => [];
        public void ApplyMoveDirect(GameState state, MoveRequest move) { }
    }

    private class FakeLobbyRepository : ILobbyRepository
    {
        private readonly List<LobbyEntity> _lobbies = [];

        public Task<LobbyEntity> CreateAsync(LobbyEntity lobby, CancellationToken cancellationToken = default)
        {
            _lobbies.Add(lobby);
            return Task.FromResult(lobby);
        }

        public Task<LobbyEntity?> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
            => Task.FromResult(_lobbies.FirstOrDefault(l => l.Code == code));

        public Task<LobbyEntity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
            => Task.FromResult(_lobbies.FirstOrDefault(l => l.Id == id));

        public Task SaveChangesAsync(CancellationToken cancellationToken = default)
            => Task.CompletedTask;

        public Task<List<LobbyEntity>> ListOpenAsync(int limit = 20, CancellationToken cancellationToken = default)
            => Task.FromResult(_lobbies.Take(limit).ToList());

        public Task<List<LobbyEntity>> ListStaleAsync(DateTimeOffset threshold, CancellationToken cancellationToken = default)
            => Task.FromResult(_lobbies.Where(l => l.CreatedAt < threshold).ToList());

        public Task<int> RemoveStaleAsync(DateTimeOffset threshold, CancellationToken cancellationToken = default)
        {
            var count = _lobbies.RemoveAll(l => l.CreatedAt < threshold);
            return Task.FromResult(count);
        }

        public void RemoveMember(LobbyMember member)
        {
            var lobby = _lobbies.FirstOrDefault(l => l.Id == member.LobbyId)
                        ?? _lobbies.FirstOrDefault(l => l.Members.Any(m => m.Id == member.Id));
            lobby?.Members.RemoveAll(m => m.Id == member.Id);
        }

        public void RemoveLobby(LobbyEntity lobby)
            => _lobbies.RemoveAll(l => l.Id == lobby.Id);
    }
}
