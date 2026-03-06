using System.Net.Http.Json;
using System.Text.Json;

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

        var payload = await res.Content.ReadFromJsonAsync<Dictionary<string, JsonElement>>();
        Assert.NotNull(payload);
        Assert.True(payload!.ContainsKey("colorDice"));
        Assert.True(payload.ContainsKey("numberDice"));
        Assert.Equal(JsonValueKind.Array, payload["colorDice"].ValueKind);
        Assert.Equal(JsonValueKind.Array, payload["numberDice"].ValueKind);
        Assert.All(payload["colorDice"].EnumerateArray(), v => Assert.Equal(JsonValueKind.String, v.ValueKind));
        Assert.All(payload["numberDice"].EnumerateArray(), v => Assert.Equal(JsonValueKind.String, v.ValueKind));
    }

    [Fact]
    public async Task Roll_Contract_ReturnsDicePayload()
    {
        var res = await _client.PostAsync("/api/gameplay/test-session/roll", null);
        res.EnsureSuccessStatusCode();

        var payload = await res.Content.ReadFromJsonAsync<Dictionary<string, JsonElement>>();
        Assert.NotNull(payload);
        Assert.True(payload!.ContainsKey("colorDice"));
        Assert.True(payload.ContainsKey("numberDice"));
        Assert.Equal(JsonValueKind.Array, payload["colorDice"].ValueKind);
        Assert.Equal(JsonValueKind.Array, payload["numberDice"].ValueKind);
        Assert.All(payload["colorDice"].EnumerateArray(), v => Assert.Equal(JsonValueKind.String, v.ValueKind));
        Assert.All(payload["numberDice"].EnumerateArray(), v => Assert.Equal(JsonValueKind.String, v.ValueKind));
    }
}
