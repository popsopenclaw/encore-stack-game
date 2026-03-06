using System.Net.Http.Json;
using Encore.Application.Contracts.Auth;
using Encore.Application.Contracts.Profile;
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
    public async Task AuthProviders_Contract_WorksForFrontendClient()
    {
        var response = await _client.GetAsync("/api/auth/providers");
        response.EnsureSuccessStatusCode();

        var payload = await response.Content.ReadFromJsonAsync<AuthProvidersResponse>();
        Assert.NotNull(payload);
        Assert.Contains(payload!.Providers, provider => provider.Id == "github");
        Assert.Contains(payload.Providers, provider => provider.Id == "local");
    }

    [Fact]
    public async Task OAuthExchange_Contract_ReturnsFrontendFields()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/oauth/github/exchange", new OAuthExchangeRequest("abc"));
        response.EnsureSuccessStatusCode();

        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>();
        Assert.NotNull(auth);
        Assert.Equal("fake-jwt", auth!.AccessToken);
        Assert.False(string.IsNullOrWhiteSpace(auth.Username));
        Assert.False(string.IsNullOrWhiteSpace(auth.PlayerName));
    }

    [Fact]
    public async Task LocalLogin_Contract_ReturnsFrontendFields()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/local/login", new LocalAuthRequest("tester@example.com", "secret123"));
        response.EnsureSuccessStatusCode();

        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>();
        Assert.NotNull(auth);
        Assert.Equal("tester@example.com", auth!.Email);
    }

    [Fact]
    public async Task Profile_Contract_ReturnsEditablePlayerFields()
    {
        var response = await _client.GetAsync("/api/profile");
        response.EnsureSuccessStatusCode();

        var profile = await response.Content.ReadFromJsonAsync<ProfileDto>();
        Assert.NotNull(profile);
        Assert.False(string.IsNullOrWhiteSpace(profile!.PlayerName));
        Assert.False(string.IsNullOrWhiteSpace(profile.Username));
    }

    [Fact]
    public async Task ProfileUpdate_Contract_ReturnsUpdatedPlayerName()
    {
        var response = await _client.PatchAsJsonAsync("/api/profile", new UpdateProfileRequest("tidal-rook-8"));
        response.EnsureSuccessStatusCode();

        var profile = await response.Content.ReadFromJsonAsync<ProfileDto>();
        Assert.NotNull(profile);
        Assert.Equal("tidal-rook-8", profile!.PlayerName);
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
        Assert.True(scorePayload![0].ContainsKey("isWinner"));
        Assert.True(scorePayload[0].ContainsKey("rank"));
        Assert.True(scorePayload[0].ContainsKey("tiebreakExclamationMarks"));

        var eventsRes = await _client.GetAsync("/api/gameplay/test-session/events");
        eventsRes.EnsureSuccessStatusCode();
        var eventsPayload = await eventsRes.Content.ReadFromJsonAsync<List<TurnEvent>>();
        Assert.NotNull(eventsPayload);
        Assert.NotEmpty(eventsPayload!);
    }

    [Fact]
    public async Task GameplayActiveSelect_Contract_AcceptsStringEnums()
    {
        var response = await _client.PostAsJsonAsync(
            "/api/gameplay/test-session/active-select",
            new
            {
                playerIndex = 0,
                colorDie = "Blue",
                numberDie = "Three",
                pass = false
            });

        response.EnsureSuccessStatusCode();
        var state = await response.Content.ReadFromJsonAsync<GameState>();
        Assert.NotNull(state);
        Assert.Equal("test-session", state!.SessionId);
    }
}
