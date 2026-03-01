using Encore.Application.Auth;
using Encore.Application.Contracts.Auth;

namespace Encore.Api.IntegrationTests.Fakes;

public class FakeAuthUseCase : IAuthUseCase
{
    public string BuildGitHubLoginUrl(string? state = null)
        => "https://github.com/login/oauth/authorize?client_id=fake";

    public Task<AuthResponse> ExchangeGitHubCodeAsync(string code, CancellationToken cancellationToken)
        => Task.FromResult(new AuthResponse("fake-jwt", "tester", "tester@example.com", "https://example.com/a.png"));
}
