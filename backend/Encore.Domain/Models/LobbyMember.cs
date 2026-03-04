namespace Encore.Domain.Models;

public class LobbyMember
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid LobbyId { get; set; }
    public Lobby? Lobby { get; set; }
    public Guid AccountId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public DateTimeOffset JoinedAt { get; set; } = DateTimeOffset.UtcNow;
}