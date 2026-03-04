using System.Net.Http.Json;

namespace Encore.Api.IntegrationTests;

public class GameplayContractRegressionTests : IClassFixture<ApiWebFactory>
{
    private readonly HttpClient _client;

    public GameplayContractRegressionTests(ApiWebFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task AvailableDice_Contract_ContainsColorAndNumberArrays()
    {
        var res = await _client.GetAsync("/api/gameplay/test-session/available-dice/0");
        res.EnsureSuccessStatusCode();

        var payload = await res.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(payload);
        Assert.True(payload!.ContainsKey("colorDice"));
        Assert.True(payload.ContainsKey("numberDice"));
    }

    [Fact]
    public async Task Roll_Contract_ReturnsDicePayload()
    {
        var res = await _client.PostAsync("/api/gameplay/test-session/roll", null);
        res.EnsureSuccessStatusCode();

        var payload = await res.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(payload);
        Assert.True(payload!.ContainsKey("colorDice"));
        Assert.True(payload.ContainsKey("numberDice"));
    }
}
