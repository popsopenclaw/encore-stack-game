using System.Net;
using System.Net.Http.Json;
using Encore.Application.Contracts.Lobby;

namespace Encore.Api.IntegrationTests;

public record ApiErrorResponse(string Code, string Message, string? CorrelationId);

public class LobbyContractTests : IClassFixture<ApiWebFactory>
{
    private readonly HttpClient _client;

    public LobbyContractTests(ApiWebFactory factory)
    {
      _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateJoinGetLeave_LobbyEndpoints_Work()
    {
        var create = await _client.PostAsJsonAsync("/api/lobby", new CreateLobbyRequest(4));
        create.EnsureSuccessStatusCode();
        var created = await create.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(created);
        Assert.False(string.IsNullOrWhiteSpace(created!.Code));
        Assert.Equal("player-1's lobby", created.Name);

        var join = await _client.PostAsJsonAsync("/api/lobby/join", new JoinLobbyRequest(created.Code));
        join.EnsureSuccessStatusCode();

        var get = await _client.GetAsync($"/api/lobby/{created.Code}");
        get.EnsureSuccessStatusCode();

        var leave = await _client.PostAsync($"/api/lobby/{created.Code}/leave", null);
        Assert.Equal(HttpStatusCode.NoContent, leave.StatusCode);
    }

    [Fact]
    public async Task HostOnlyStartMatch_IsEnforced()
    {
        var create = await _client.PostAsJsonAsync("/api/lobby", new CreateLobbyRequest(4));
        create.EnsureSuccessStatusCode();
        var created = await create.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(created);

        var startHost = await _client.PostAsJsonAsync($"/api/lobby/{created!.Code}/start", new StartLobbyMatchRequest("Game"));
        startHost.EnsureSuccessStatusCode();
        var started = await startHost.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(started);
        Assert.True(started!.ContainsKey("sessionId"));

        var get = await _client.GetAsync($"/api/lobby/{created.Code}");
        get.EnsureSuccessStatusCode();
        var startedLobby = await get.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(startedLobby);
        Assert.True(startedLobby!.HasActiveGame);
        Assert.Equal(started["sessionId"], startedLobby.ActiveSessionId);

        using var nonHostReq = new HttpRequestMessage(HttpMethod.Post, $"/api/lobby/{created.Code}/start")
        {
            Content = JsonContent.Create(new StartLobbyMatchRequest("Game"))
        };
        nonHostReq.Headers.Add("X-Test-Sub", "22222222-2222-2222-2222-222222222222");

        var startNonHost = await _client.SendAsync(nonHostReq);
        Assert.Equal(HttpStatusCode.Forbidden, startNonHost.StatusCode);

        var err = await startNonHost.Content.ReadFromJsonAsync<ApiErrorResponse>();
        Assert.NotNull(err);
        Assert.Equal("forbidden", err!.Code);
        Assert.False(string.IsNullOrWhiteSpace(err.Message));
    }

    [Fact]
    public async Task JoiningAnotherLobby_RemovesPlayerFromPreviousLobby()
    {
        using var createFirst = new HttpRequestMessage(HttpMethod.Post, "/api/lobby")
        {
            Content = JsonContent.Create(new CreateLobbyRequest(4))
        };
        createFirst.Headers.Add("X-Test-Sub", "11111111-1111-1111-1111-111111111111");

        var firstResponse = await _client.SendAsync(createFirst);
        firstResponse.EnsureSuccessStatusCode();
        var firstLobby = await firstResponse.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(firstLobby);

        using var createSecond = new HttpRequestMessage(HttpMethod.Post, "/api/lobby")
        {
            Content = JsonContent.Create(new CreateLobbyRequest(4))
        };
        createSecond.Headers.Add("X-Test-Sub", "22222222-2222-2222-2222-222222222222");

        var secondResponse = await _client.SendAsync(createSecond);
        secondResponse.EnsureSuccessStatusCode();
        var secondLobby = await secondResponse.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(secondLobby);

        using var joinSecond = new HttpRequestMessage(HttpMethod.Post, "/api/lobby/join")
        {
            Content = JsonContent.Create(new JoinLobbyRequest(secondLobby!.Code))
        };
        joinSecond.Headers.Add("X-Test-Sub", "11111111-1111-1111-1111-111111111111");

        var joinResponse = await _client.SendAsync(joinSecond);
        joinResponse.EnsureSuccessStatusCode();

        using var getFirst = new HttpRequestMessage(HttpMethod.Get, $"/api/lobby/{firstLobby!.Code}");
        getFirst.Headers.Add("X-Test-Sub", "11111111-1111-1111-1111-111111111111");

        var firstLobbyGet = await _client.SendAsync(getFirst);
        Assert.Equal(HttpStatusCode.NotFound, firstLobbyGet.StatusCode);

        using var getSecond = new HttpRequestMessage(HttpMethod.Get, $"/api/lobby/{secondLobby.Code}");
        getSecond.Headers.Add("X-Test-Sub", "11111111-1111-1111-1111-111111111111");

        var secondLobbyGet = await _client.SendAsync(getSecond);
        secondLobbyGet.EnsureSuccessStatusCode();
        var secondLobbyState = await secondLobbyGet.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(secondLobbyState);
        Assert.Equal(2, secondLobbyState!.Members.Count);
    }
}
