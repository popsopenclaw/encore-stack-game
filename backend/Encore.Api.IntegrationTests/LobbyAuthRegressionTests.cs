using System.Net;
using System.Net.Http.Json;
using Encore.Application.Contracts.Lobby;

namespace Encore.Api.IntegrationTests;

public class LobbyAuthRegressionTests : IClassFixture<ApiWebFactory>
{
    private readonly HttpClient _client;

    public LobbyAuthRegressionTests(ApiWebFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateLobby_WithInvalidSubClaim_Returns401()
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/lobby")
        {
            Content = JsonContent.Create(new CreateLobbyRequest(4))
        };
        request.Headers.Add("X-Test-Sub", "not-a-guid");

        var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task JoinLobby_WithInvalidSubClaim_Returns401()
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/lobby/join")
        {
            Content = JsonContent.Create(new JoinLobbyRequest("ABC123"))
        };
        request.Headers.Add("X-Test-Sub", "not-a-guid");

        var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
