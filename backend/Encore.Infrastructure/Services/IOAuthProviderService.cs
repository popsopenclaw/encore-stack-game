namespace Encore.Infrastructure.Services;

public interface IOAuthProviderService
{
    string Id { get; }
    string Label { get; }

    string BuildAuthorizeUrl(string? state);
    Task<OAuthProviderIdentity> ExchangeCodeAsync(string code, CancellationToken cancellationToken);
}
