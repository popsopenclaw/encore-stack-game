using Encore.Application.Abstractions;
using Encore.Application.Contracts.Auth;
using Encore.Domain.Models;
using Encore.Infrastructure.Services;

namespace Encore.Infrastructure.Adapters;

public class AuthGatewayAdapter(AuthAccountService service) : IAuthGateway
{
    public IReadOnlyList<AuthProviderDto> GetProviders() => service.GetProviders();

    public string BuildAuthorizeUrl(string provider, string? state) => service.BuildAuthorizeUrl(provider, state);

    public Task<Account> ExchangeCodeAsync(string provider, string code, CancellationToken cancellationToken)
        => service.ExchangeCodeAsync(provider, code, cancellationToken);

    public Task<Account> LoginLocalAsync(string email, string password, CancellationToken cancellationToken)
        => service.LoginLocalAsync(email, password, cancellationToken);

    public Task<Account> RegisterLocalAsync(string email, string password, CancellationToken cancellationToken)
        => service.RegisterLocalAsync(email, password, cancellationToken);

    public Task LinkOAuthAsync(Guid accountId, string provider, string code, CancellationToken cancellationToken)
        => service.LinkOAuthAsync(accountId, provider, code, cancellationToken);

    public Task LinkLocalAsync(Guid accountId, string email, string password, CancellationToken cancellationToken)
        => service.LinkLocalAsync(accountId, email, password, cancellationToken);
}
