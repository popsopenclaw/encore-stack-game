using Encore.Application.Contracts.Profile;
using Encore.Application.Profile;

namespace Encore.Api.IntegrationTests.Fakes;

public class FakeProfileUseCase : IProfileUseCase
{
    private readonly Dictionary<Guid, ProfileDto> _profiles = [];

    public Task<ProfileDto> GetAsync(Guid accountId, CancellationToken cancellationToken = default)
    {
        if (_profiles.TryGetValue(accountId, out var profile))
            return Task.FromResult(profile);

        profile = new ProfileDto(
            accountId,
            "ember-falcon-42",
            "tester",
            "tester@example.com",
            "https://example.com/a.png");
        _profiles[accountId] = profile;
        return Task.FromResult(profile);
    }

    public async Task<ProfileDto> UpdateAsync(Guid accountId, UpdateProfileRequest request, CancellationToken cancellationToken = default)
    {
        var current = await GetAsync(accountId, cancellationToken);
        var next = current with { PlayerName = request.PlayerName.Trim() };
        _profiles[accountId] = next;
        return next;
    }
}
