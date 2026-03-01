using Encore.Domain.Models;

namespace Encore.Application.Abstractions;

public interface IAuthGateway
{
    string BuildAuthorizeUrl(string? state);
    Task<Account> ExchangeCodeAndUpsertAsync(string code, CancellationToken cancellationToken);
}
