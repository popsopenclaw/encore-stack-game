namespace Encore.Domain.Models;

public class AccountLink
{
    public string Provider { get; set; } = string.Empty;
    public string ExternalId { get; set; } = string.Empty;
    public Guid AccountId { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public Account Account { get; set; } = null!;
}
