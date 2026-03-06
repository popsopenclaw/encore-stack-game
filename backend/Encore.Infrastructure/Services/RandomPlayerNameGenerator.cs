using Encore.Application.Abstractions;

namespace Encore.Infrastructure.Services;

public class RandomPlayerNameGenerator : IPlayerNameGenerator
{
    private static readonly string[] Adjectives =
    [
        "amber",
        "brisk",
        "cinder",
        "daring",
        "ember",
        "fable",
        "glint",
        "harbor",
        "jolly",
        "lumen",
        "merry",
        "nova",
        "opal",
        "plucky",
        "quartz",
        "rally",
        "spruce",
        "tidal",
        "vivid",
        "willow"
    ];

    private static readonly string[] Nouns =
    [
        "badger",
        "comet",
        "falcon",
        "harp",
        "iris",
        "lantern",
        "otter",
        "panda",
        "rook",
        "sparrow",
        "thunder",
        "voyager",
        "whistle",
        "zephyr"
    ];

    public string GenerateCandidate()
    {
        var adjective = Adjectives[Random.Shared.Next(Adjectives.Length)];
        var noun = Nouns[Random.Shared.Next(Nouns.Length)];
        var number = Random.Shared.Next(10, 999);
        return $"{adjective}-{noun}-{number}";
    }
}
