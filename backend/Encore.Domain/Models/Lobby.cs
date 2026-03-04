namespace Encore.Domain.Models;

public class Lobby
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public Guid HostAccountId { get; set; }
    public int MaxPlayers { get; set; } = 6;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public List<LobbyMember> Members { get; set; } = [];
}
