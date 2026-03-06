using Encore.Application.Abstractions;
using Encore.Application;
using Encore.Application.Contracts.Profile;
using Encore.Application.Profile;
using Encore.Domain.Models;

namespace Encore.Api.Tests;

public class ProfileUseCaseTests
{
    [Fact]
    public async Task UpdateAsync_ChangesPlayerName()
    {
        var accountId = Guid.NewGuid();
        var repo = new FakeAccountRepository(accountId, "ember-falcon-42");
        var useCase = new ProfileUseCase(repo);

        var updated = await useCase.UpdateAsync(accountId, new UpdateProfileRequest("tidal-rook-8"));

        Assert.Equal("tidal-rook-8", updated.PlayerName);
        Assert.Equal("TIDAL-ROOK-8", repo.Account.NormalizedPlayerName);
    }

    [Fact]
    public async Task UpdateAsync_RejectsDuplicatePlayerName()
    {
        var accountId = Guid.NewGuid();
        var repo = new FakeAccountRepository(accountId, "ember-falcon-42");
        repo.Add(Guid.NewGuid(), "tidal-rook-8");
        var useCase = new ProfileUseCase(repo);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            useCase.UpdateAsync(accountId, new UpdateProfileRequest("TIDAL-rook-8")));
    }

    [Fact]
    public async Task UpdateAsync_RejectsInvalidCharacters()
    {
        var accountId = Guid.NewGuid();
        var repo = new FakeAccountRepository(accountId, "ember-falcon-42");
        var useCase = new ProfileUseCase(repo);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            useCase.UpdateAsync(accountId, new UpdateProfileRequest("bad name")));
    }

    [Fact]
    public async Task GetAsync_WithMissingAccount_ThrowsInvalidSession()
    {
        var repo = new FakeAccountRepository(Guid.NewGuid(), "ember-falcon-42");
        var useCase = new ProfileUseCase(repo);

        await Assert.ThrowsAsync<InvalidSessionException>(() =>
            useCase.GetAsync(Guid.NewGuid()));
    }

    private class FakeAccountRepository : IAccountRepository
    {
        private readonly Dictionary<Guid, Account> _accounts = [];

        public FakeAccountRepository(Guid id, string playerName)
        {
            Account = Add(id, playerName);
        }

        public Account Account { get; }

        public Account Add(Guid id, string playerName)
        {
            var account = new Account
            {
                Id = id,
                Username = $"gh-{id:N}",
                PlayerName = playerName,
                NormalizedPlayerName = playerName.ToUpperInvariant(),
                Email = "player@example.com",
                AvatarUrl = "https://example.com/avatar.png"
            };
            _accounts[id] = account;
            return account;
        }

        public Task<Account?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
            => Task.FromResult(_accounts.TryGetValue(id, out var account) ? account : null);

        public Task<List<Account>> GetByIdsAsync(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken = default)
            => Task.FromResult(ids.Where(_accounts.ContainsKey).Select(id => _accounts[id]).ToList());

        public Task<bool> ExistsByNormalizedPlayerNameAsync(
            string normalizedPlayerName,
            Guid? excludeAccountId = null,
            CancellationToken cancellationToken = default)
            => Task.FromResult(_accounts.Values.Any(
                a => a.NormalizedPlayerName == normalizedPlayerName &&
                    (!excludeAccountId.HasValue || a.Id != excludeAccountId.Value)));

        public Task SaveChangesAsync(CancellationToken cancellationToken = default)
            => Task.CompletedTask;
    }
}
