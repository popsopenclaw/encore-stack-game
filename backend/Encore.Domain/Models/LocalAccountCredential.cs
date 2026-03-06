namespace Encore.Domain.Models;

public class LocalAccountCredential
{
    public Guid AccountId { get; set; }
    public byte[] PasswordHash { get; set; } = [];
    public byte[] Salt { get; set; } = [];
    public int HashVersion { get; set; } = 1;

    public Account Account { get; set; } = null!;
}
