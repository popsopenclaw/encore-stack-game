using Encore.Application.Auth;
using Encore.Application.Contracts.Auth;

namespace Encore.Api.IntegrationTests.Fakes;

public class FakeAuthUseCase : IAuthUseCase
{
    public AuthProvidersResponse GetProviders()
        => new([
            new AuthProviderDto("github", "GitHub", "oauth"),
            new AuthProviderDto("local", "Email", "credentials")
        ]);

    public string BuildOAuthLoginUrl(string provider, string? state = null)
        => $"https://{provider}.example.test/oauth/authorize";

    public Task<AuthResponse> ExchangeOAuthCodeAsync(string provider, string code, CancellationToken cancellationToken)
        => Task.FromResult(new AuthResponse("fake-jwt", "tester", "tester@example.com", "https://example.com/a.png", "ember-falcon-42"));

    public Task<AuthResponse> LoginLocalAsync(string email, string password, CancellationToken cancellationToken)
        => Task.FromResult(new AuthResponse("fake-jwt", "tester", email, string.Empty, "ember-falcon-42"));

    public Task<AuthResponse> RegisterLocalAsync(string email, string password, CancellationToken cancellationToken)
        => Task.FromResult(new AuthResponse("fake-jwt", "tester", email, string.Empty, "ember-falcon-42"));

    public Task LinkOAuthAsync(Guid accountId, string provider, string code, CancellationToken cancellationToken)
        => Task.CompletedTask;

    public Task LinkLocalAsync(Guid accountId, string email, string password, CancellationToken cancellationToken)
        => Task.CompletedTask;
}
