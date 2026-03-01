using Encore.Api.Services;

namespace Encore.Application.Auth;

public class AuthUseCase(GitHubOAuthService gitHubOAuthService, JwtTokenService jwtTokenService) : IAuthUseCase
{
    public string BuildGitHubLoginUrl(string? state = null)
        => gitHubOAuthService.BuildAuthorizeUrl(state);

    public async Task<AuthResult> ExchangeGitHubCodeAsync(string code, CancellationToken cancellationToken)
    {
        var account = await gitHubOAuthService.ExchangeCodeAndUpsertAsync(code, cancellationToken);
        var token = jwtTokenService.CreateToken(account);
        return new AuthResult(token, account.Username, account.Email, account.AvatarUrl);
    }
}
