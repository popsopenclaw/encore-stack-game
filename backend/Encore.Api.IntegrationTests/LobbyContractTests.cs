using System.Net;
using System.Net.Http.Json;
using Encore.Application.Contracts.Lobby;

namespace Encore.Api.IntegrationTests;

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
        var create = await _client.PostAsJsonAsync("/api/lobby", new CreateLobbyRequest("My Lobby", 4, "Host"));
        create.EnsureSuccessStatusCode();
        var created = await create.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(created);
        Assert.False(string.IsNullOrWhiteSpace(created!.Code));

        var join = await _client.PostAsJsonAsync("/api/lobby/join", new JoinLobbyRequest(created.Code, "Player2"));
        join.EnsureSuccessStatusCode();

        var get = await _client.GetAsync($"/api/lobby/{created.Code}");
        get.EnsureSuccessStatusCode();

        var leave = await _client.PostAsync($"/api/lobby/{created.Code}/leave", null);
        Assert.Equal(HttpStatusCode.NoContent, leave.StatusCode);
    }

    [Fact]
    public async Task HostOnlyStartMatch_IsEnforced()
    {
        var create = await _client.PostAsJsonAsync("/api/lobby", new CreateLobbyRequest("Game Lobby", 4, "Host"));
        create.EnsureSuccessStatusCode();
        var created = await create.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(created);

        var startHost = await _client.PostAsJsonAsync($"/api/lobby/{created!.Code}/start", new StartLobbyMatchRequest("Game"));
        startHost.EnsureSuccessStatusCode();

        using var nonHostReq = new HttpRequestMessage(HttpMethod.Post, $"/api/lobby/{created.Code}/start")
        {
            Content = JsonContent.Create(new StartLobbyMatchRequest("Game"))
        };
        nonHostReq.Headers.Add("X-Test-Sub", "22222222-2222-2222-2222-222222222222");

        var startNonHost = await _client.SendAsync(nonHostReq);
        Assert.Equal(HttpStatusCode.Forbidden, startNonHost.StatusCode);
    }
}
