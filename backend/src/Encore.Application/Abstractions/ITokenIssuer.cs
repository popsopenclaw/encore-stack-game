using Encore.Api.Models;

namespace Encore.Application.Abstractions;

public interface ITokenIssuer
{
    string CreateToken(Account account);
}
