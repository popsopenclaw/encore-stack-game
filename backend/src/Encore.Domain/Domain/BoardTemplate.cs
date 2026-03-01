using System.Text.Json.Serialization;

namespace Encore.Api.Domain;

public class BoardTemplate
{
    [JsonPropertyName("name")]
    public required string Name { get; set; }

    [JsonPropertyName("rows")]
    public required string[] Rows { get; set; }

    [JsonPropertyName("stars")]
    public required List<StarCell> Stars { get; set; }
}

public class StarCell
{
    [JsonPropertyName("x")]
    public int X { get; set; }
    [JsonPropertyName("y")]
    public int Y { get; set; }
}
