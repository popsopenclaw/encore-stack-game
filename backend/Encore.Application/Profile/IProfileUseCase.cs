using Encore.Application.Contracts.Profile;

namespace Encore.Application.Profile;

public interface IProfileUseCase
{
    Task<ProfileDto> GetAsync(Guid accountId, CancellationToken cancellationToken = default);
    Task<ProfileDto> UpdateAsync(Guid accountId, UpdateProfileRequest request, CancellationToken cancellationToken = default);
}
