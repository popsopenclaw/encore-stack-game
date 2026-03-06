using Encore.Application.Abstractions;
using Encore.Application.Contracts.Profile;

namespace Encore.Application.Profile;

public class ProfileUseCase(IAccountRepository repository) : IProfileUseCase
{
    public async Task<ProfileDto> GetAsync(Guid accountId, CancellationToken cancellationToken = default)
    {
        var account = await repository.GetByIdAsync(accountId, cancellationToken)
            ?? throw new KeyNotFoundException("Account not found");

        return ToDto(account);
    }

    public async Task<ProfileDto> UpdateAsync(Guid accountId, UpdateProfileRequest request, CancellationToken cancellationToken = default)
    {
        var account = await repository.GetByIdAsync(accountId, cancellationToken)
            ?? throw new KeyNotFoundException("Account not found");

        var playerName = PlayerNamePolicy.Validate(request.PlayerName);
        var normalized = PlayerNamePolicy.Normalize(playerName);

        if (!string.Equals(account.NormalizedPlayerName, normalized, StringComparison.Ordinal))
        {
            var exists = await repository.ExistsByNormalizedPlayerNameAsync(
                normalized,
                accountId,
                cancellationToken);
            if (exists)
                throw new InvalidOperationException("Player name is already taken.");
        }

        account.PlayerName = playerName;
        account.NormalizedPlayerName = normalized;
        account.UpdatedAt = DateTimeOffset.UtcNow;

        await repository.SaveChangesAsync(cancellationToken);
        return ToDto(account);
    }

    private static ProfileDto ToDto(Encore.Domain.Models.Account account)
        => new(
            account.Id,
            account.PlayerName,
            account.Username,
            account.Email,
            account.AvatarUrl);
}
