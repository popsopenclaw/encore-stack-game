namespace Encore.Api.Models;

public class Account
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public long GitHubId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string AvatarUrl { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
