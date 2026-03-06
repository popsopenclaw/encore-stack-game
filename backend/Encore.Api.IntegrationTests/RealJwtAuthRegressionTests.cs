using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text;
using Encore.Application.Contracts.Lobby;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Encore.Api.IntegrationTests;

public class RealJwtAuthRegressionTests : IClassFixture<RawApiWebFactory>
{
    private readonly HttpClient _client;
    private readonly IConfiguration _configuration;

    public RealJwtAuthRegressionTests(RawApiWebFactory factory)
    {
        _client = factory.CreateClient();
        _configuration = factory.Services.GetRequiredService<IConfiguration>();
    }

    [Fact]
    public async Task CreateLobby_WithRealBearerToken_UsesSubClaimSuccessfully()
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/lobby")
        {
            Content = JsonContent.Create(new CreateLobbyRequest("My Lobby", 4))
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken(Guid.NewGuid()));

        var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private string CreateToken(Guid accountId)
    {
        var issuer = _configuration["Jwt:Issuer"] ?? "encore-api";
        var audience = _configuration["Jwt:Audience"] ?? "encore-clients";
        var signingKey = _configuration["Jwt:SigningKey"]
            ?? throw new InvalidOperationException("Missing Jwt signing key in test configuration.");

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, accountId.ToString())
        };

        var token = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            expires: DateTime.UtcNow.AddMinutes(30),
            signingCredentials: new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)),
                SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
