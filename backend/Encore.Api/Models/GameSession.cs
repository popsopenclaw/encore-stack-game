namespace Encore.Api.Models;

public class GameSession
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public Guid OwnerAccountId { get; set; }
    public string Name { get; set; } = "New Session";
    public string StateJson { get; set; } = "{}";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
