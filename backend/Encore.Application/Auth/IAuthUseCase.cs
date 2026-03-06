using Encore.Application.Contracts.Auth;

namespace Encore.Application.Auth;

public interface IAuthUseCase
{
    AuthProvidersResponse GetProviders();
    string BuildOAuthLoginUrl(string provider, string? state = null);
    Task<AuthResponse> ExchangeOAuthCodeAsync(string provider, string code, CancellationToken cancellationToken);
    Task<AuthResponse> LoginLocalAsync(string email, string password, CancellationToken cancellationToken);
    Task<AuthResponse> RegisterLocalAsync(string email, string password, CancellationToken cancellationToken);
    Task LinkOAuthAsync(Guid accountId, string provider, string code, CancellationToken cancellationToken);
    Task LinkLocalAsync(Guid accountId, string email, string password, CancellationToken cancellationToken);
}
