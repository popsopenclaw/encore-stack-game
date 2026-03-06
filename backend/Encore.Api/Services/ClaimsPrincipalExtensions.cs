using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Encore.Application;

namespace Encore.Api.Services;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetRequiredAccountId(this ClaimsPrincipal user)
    {
        var sub = user.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub)?.Value
            ?? user.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
        if (Guid.TryParse(sub, out var id))
        {
            return id;
        }

        throw new InvalidSessionException("Session is invalid.");
    }
}
