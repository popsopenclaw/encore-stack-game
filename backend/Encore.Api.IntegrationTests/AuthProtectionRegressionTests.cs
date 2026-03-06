using System.Net;

namespace Encore.Api.IntegrationTests;

public class AuthProtectionRegressionTests : IClassFixture<RawApiWebFactory>
{
    private readonly HttpClient _client;

    public AuthProtectionRegressionTests(RawApiWebFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ProtectedEndpoint_WithoutToken_Returns401()
    {
        var res = await _client.GetAsync("/api/gameplay/test-session");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task ProtectedEndpoint_WithInvalidBearerToken_Returns401()
    {
        using var req = new HttpRequestMessage(HttpMethod.Get, "/api/gameplay/test-session");
        req.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", "this.is.not.valid");

        var res = await _client.SendAsync(req);
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task PublicAuthUrlEndpoint_WithoutToken_IsAccessible()
    {
        var res = await _client.GetAsync("/api/auth/providers");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }
}
