using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Encore.Api.Models;
using Microsoft.IdentityModel.Tokens;

namespace Encore.Api.Services;

public class JwtTokenService(IConfiguration configuration)
{
    public string CreateToken(Account account)
    {
        var key = configuration["Jwt:SigningKey"] ?? throw new InvalidOperationException("Missing Jwt:SigningKey");
        var issuer = configuration["Jwt:Issuer"] ?? "encore-api";
        var audience = configuration["Jwt:Audience"] ?? "encore-clients";

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, account.Id.ToString()),
            new Claim("username", account.Username),
            new Claim("github_id", account.GitHubId.ToString())
        };

        var creds = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
