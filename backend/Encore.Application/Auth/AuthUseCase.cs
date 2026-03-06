using Encore.Application.Abstractions;
using Encore.Application.Contracts.Auth;

namespace Encore.Application.Auth;

public class AuthUseCase(IAuthGateway authGateway, ITokenIssuer tokenIssuer) : IAuthUseCase
{
    public string BuildGitHubLoginUrl(string? state = null)
        => authGateway.BuildAuthorizeUrl(state);

    public async Task<AuthResponse> ExchangeGitHubCodeAsync(string code, CancellationToken cancellationToken)
    {
        var account = await authGateway.ExchangeCodeAndUpsertAsync(code, cancellationToken);
        var token = tokenIssuer.CreateToken(account);
        return new AuthResponse(token, account.Username, account.Email, account.AvatarUrl, account.PlayerName);
    }
}
