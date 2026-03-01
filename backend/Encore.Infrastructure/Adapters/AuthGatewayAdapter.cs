using Encore.Domain.Models;
using Encore.Infrastructure.Services;
using Encore.Application.Abstractions;

namespace Encore.Infrastructure.Adapters;

public class AuthGatewayAdapter(GitHubOAuthService service) : IAuthGateway
{
    public string BuildAuthorizeUrl(string? state) => service.BuildAuthorizeUrl(state);

    public Task<Account> ExchangeCodeAndUpsertAsync(string code, CancellationToken cancellationToken)
        => service.ExchangeCodeAndUpsertAsync(code, cancellationToken);
}
