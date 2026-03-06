using Encore.Application.Abstractions;
using Encore.Application.Contracts.Auth;

namespace Encore.Application.Auth;

public class AuthUseCase(IAuthGateway authGateway, ITokenIssuer tokenIssuer) : IAuthUseCase
{
    public AuthProvidersResponse GetProviders()
        => new(authGateway.GetProviders());

    public string BuildOAuthLoginUrl(string provider, string? state = null)
        => authGateway.BuildAuthorizeUrl(provider, state);

    public async Task<AuthResponse> ExchangeOAuthCodeAsync(string provider, string code, CancellationToken cancellationToken)
    {
        var account = await authGateway.ExchangeCodeAsync(provider, code, cancellationToken);
        return ToResponse(account);
    }

    public async Task<AuthResponse> LoginLocalAsync(string email, string password, CancellationToken cancellationToken)
        => ToResponse(await authGateway.LoginLocalAsync(email, password, cancellationToken));

    public async Task<AuthResponse> RegisterLocalAsync(string email, string password, CancellationToken cancellationToken)
        => ToResponse(await authGateway.RegisterLocalAsync(email, password, cancellationToken));

    public Task LinkOAuthAsync(Guid accountId, string provider, string code, CancellationToken cancellationToken)
        => authGateway.LinkOAuthAsync(accountId, provider, code, cancellationToken);

    public Task LinkLocalAsync(Guid accountId, string email, string password, CancellationToken cancellationToken)
        => authGateway.LinkLocalAsync(accountId, email, password, cancellationToken);

    private AuthResponse ToResponse(Encore.Domain.Models.Account account)
        => new(tokenIssuer.CreateToken(account), account.Username, account.Email, account.AvatarUrl, account.PlayerName);
}
