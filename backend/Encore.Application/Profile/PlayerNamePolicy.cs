using System.Text.RegularExpressions;

namespace Encore.Application.Profile;

public static partial class PlayerNamePolicy
{
    public const int MaxLength = 24;
    public const int MinLength = 3;

    [GeneratedRegex("^[A-Za-z0-9_-]+$")]
    private static partial Regex AllowedPattern();

    public static string Normalize(string value)
        => value.Trim().ToUpperInvariant();

    public static string Validate(string? value)
    {
        var trimmed = value?.Trim() ?? string.Empty;
        if (trimmed.Length < MinLength)
            throw new InvalidOperationException($"Player name must be at least {MinLength} characters.");
        if (trimmed.Length > MaxLength)
            throw new InvalidOperationException($"Player name must be at most {MaxLength} characters.");
        if (!AllowedPattern().IsMatch(trimmed))
            throw new InvalidOperationException("Player name may only contain letters, numbers, hyphens, and underscores.");

        return trimmed;
    }
}
