namespace Encore.Domain.Models;

public class Account
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Username { get; set; } = string.Empty;
    public string PlayerName { get; set; } = string.Empty;
    public string NormalizedPlayerName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string AvatarUrl { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<AccountLink> Links { get; set; } = [];
    public LocalAccountCredential? LocalCredential { get; set; }
}
