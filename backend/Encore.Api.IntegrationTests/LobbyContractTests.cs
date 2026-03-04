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
    public async Task CreateJoinListLeave_LobbyFlow_Works()
    {
        var create = await _client.PostAsJsonAsync("/api/lobby", new CreateLobbyRequest("My Lobby", 4, "Host"));
        if (!create.IsSuccessStatusCode)
        {
            var body = await create.Content.ReadAsStringAsync();
            throw new Exception($"Create lobby failed: {(int)create.StatusCode} {body}");
        }
        var created = await create.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(created);
        Assert.Equal("My Lobby", created!.Name);

        var code = string.IsNullOrWhiteSpace(created.Code) ? "ABC123" : created.Code;

        var join = await _client.PostAsJsonAsync("/api/lobby/join", new JoinLobbyRequest(code, "Player2"));
        join.EnsureSuccessStatusCode();
        var joined = await join.Content.ReadFromJsonAsync<LobbyDto>();
        Assert.NotNull(joined);
        Assert.True(joined!.Members.Count >= 1);

        var get = await _client.GetAsync($"/api/lobby/{created.Code}");
        get.EnsureSuccessStatusCode();

        var list = await _client.GetAsync("/api/lobby?limit=10");
        list.EnsureSuccessStatusCode();
        var lobbies = await list.Content.ReadFromJsonAsync<List<LobbyDto>>();
        Assert.NotNull(lobbies);
        Assert.Contains(lobbies!, l => l.Code == created.Code);

        var patch = await _client.PatchAsJsonAsync($"/api/lobby/{created.Code}", new UpdateLobbyRequest("Renamed", 4));
        patch.EnsureSuccessStatusCode();

        var leave = await _client.PostAsync($"/api/lobby/{created.Code}/leave", null);
        Assert.Equal(HttpStatusCode.NoContent, leave.StatusCode);
    }
}
