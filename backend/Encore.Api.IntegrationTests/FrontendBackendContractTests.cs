using System.Net.Http.Json;
using Encore.Application.Contracts.Auth;
using Encore.Domain;

namespace Encore.Api.IntegrationTests;

public class FrontendBackendContractTests : IClassFixture<ApiWebFactory>
{
    private readonly HttpClient _client;

    public FrontendBackendContractTests(ApiWebFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task AuthUrl_Contract_WorksForFrontendClient()
    {
        var response = await _client.GetAsync("/api/auth/github/url?state=test");
        response.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(payload);
        Assert.True(payload!.ContainsKey("url"));
        Assert.StartsWith("https://github.com/login/oauth/authorize", payload["url"]);
    }

    [Fact]
    public async Task AuthExchange_Contract_ReturnsFrontendFields()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/github/exchange", new GithubExchangeRequest("abc"));
        response.EnsureSuccessStatusCode();

        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>();
        Assert.NotNull(auth);
        Assert.Equal("fake-jwt", auth!.AccessToken);
        Assert.False(string.IsNullOrWhiteSpace(auth.Username));
    }

    [Fact]
    public async Task GameplayStart_Contract_ReturnsSessionAndPlayers()
    {
        var response = await _client.PostAsJsonAsync("/api/gameplay/start", new StartGameRequest(["p1", "p2"]));
        response.EnsureSuccessStatusCode();

        var state = await response.Content.ReadFromJsonAsync<GameState>();
        Assert.NotNull(state);
        Assert.Equal("test-session", state!.SessionId);
        Assert.Equal(2, state.Players.Count);
    }

    [Fact]
    public async Task GameplayScoreAndEvents_Contract_IsStableForFrontend()
    {
        var score = await _client.GetAsync("/api/gameplay/test-session/score");
        score.EnsureSuccessStatusCode();
        var scorePayload = await score.Content.ReadFromJsonAsync<List<Dictionary<string, object>>>();
        Assert.NotNull(scorePayload);
        Assert.NotEmpty(scorePayload!);

        var eventsRes = await _client.GetAsync("/api/gameplay/test-session/events");
        eventsRes.EnsureSuccessStatusCode();
        var eventsPayload = await eventsRes.Content.ReadFromJsonAsync<List<TurnEvent>>();
        Assert.NotNull(eventsPayload);
        Assert.NotEmpty(eventsPayload!);
    }
}
