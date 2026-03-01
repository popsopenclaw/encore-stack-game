namespace Encore.Application.Auth;

public interface IAuthUseCase
{
    string BuildGitHubLoginUrl(string? state = null);
    Task<AuthResult> ExchangeGitHubCodeAsync(string code, CancellationToken cancellationToken);
}
