using System.Net;

namespace Encore.Api.IntegrationTests;

public class LobbyHubContractTests : IClassFixture<ApiWebFactory>
{
    private readonly HttpClient _client;

    public LobbyHubContractTests(ApiWebFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task LobbyHub_NegotiateEndpoint_IsReachable()
    {
        var res = await _client.PostAsync("/hubs/lobby/negotiate?negotiateVersion=1", content: null);

        // Depending on auth middleware order this can be 200 or unauthorized;
        // both prove the endpoint exists and is wired.
        Assert.True(
            res.StatusCode is HttpStatusCode.OK or HttpStatusCode.Unauthorized,
            $"Unexpected status code: {res.StatusCode}");
    }
}
