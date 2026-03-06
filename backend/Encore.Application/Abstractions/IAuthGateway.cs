using Encore.Domain.Models;

namespace Encore.Application.Abstractions;

public interface IAuthGateway
{
    IReadOnlyList<Contracts.Auth.AuthProviderDto> GetProviders();
    string BuildAuthorizeUrl(string provider, string? state);
    Task<Account> ExchangeCodeAsync(string provider, string code, CancellationToken cancellationToken);
    Task<Account> LoginLocalAsync(string email, string password, CancellationToken cancellationToken);
    Task<Account> RegisterLocalAsync(string email, string password, CancellationToken cancellationToken);
    Task LinkOAuthAsync(Guid accountId, string provider, string code, CancellationToken cancellationToken);
    Task LinkLocalAsync(Guid accountId, string email, string password, CancellationToken cancellationToken);
}
