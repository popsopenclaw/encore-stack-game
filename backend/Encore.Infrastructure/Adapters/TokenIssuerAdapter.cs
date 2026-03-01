using Encore.Domain.Models;
using Encore.Infrastructure.Services;
using Encore.Application.Abstractions;

namespace Encore.Infrastructure.Adapters;

public class TokenIssuerAdapter(JwtTokenService service) : ITokenIssuer
{
    public string CreateToken(Account account) => service.CreateToken(account);
}
