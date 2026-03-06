namespace Encore.Infrastructure.Services;

public record OAuthProviderIdentity(
    string Provider,
    string ExternalId,
    string? Email,
    string AvatarUrl);
