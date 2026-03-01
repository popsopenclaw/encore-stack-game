using Encore.Application.Contracts.Auth;

namespace Encore.Application.Auth;

public interface IAuthUseCase
{
    string BuildGitHubLoginUrl(string? state = null);
    Task<AuthResponse> ExchangeGitHubCodeAsync(string code, CancellationToken cancellationToken);
}
