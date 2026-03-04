using Encore.Application.Abstractions;
using Encore.Application.Contracts.Lobby;
using Encore.Application.Lobby;
using Encore.Domain.Models;
using LobbyEntity = Encore.Domain.Models.Lobby;

namespace Encore.Api.Tests;

public class LobbyUseCaseTests
{
    [Fact]
    public async Task HostLeaves_TransfersHostToOldestRemainingMember()
    {
        var repo = new FakeLobbyRepository();
        var useCase = new LobbyUseCase(repo);

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
        var useCase = new LobbyUseCase(repo);

        var hostId = Guid.NewGuid();
        var created = await useCase.CreateAsync(hostId, new CreateLobbyRequest("L", 4, "Host"));

        await useCase.LeaveAsync(hostId, created.Code);

        var lobby = await repo.GetByCodeAsync(created.Code);
        Assert.Null(lobby);
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
