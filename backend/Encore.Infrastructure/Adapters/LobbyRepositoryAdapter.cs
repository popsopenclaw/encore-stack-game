using Encore.Application.Abstractions;
using Encore.Domain.Models;
using Encore.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Encore.Infrastructure.Adapters;

public class LobbyRepositoryAdapter(AppDbContext db) : ILobbyRepository
{
    public async Task<Lobby> CreateAsync(Lobby lobby, CancellationToken cancellationToken = default)
    {
        await db.Lobbies.AddAsync(lobby, cancellationToken);
        return lobby;
    }

    public Task<Lobby?> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
        => db.Lobbies.Include(l => l.Members).FirstOrDefaultAsync(l => l.Code == code, cancellationToken);

    public Task<Lobby?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => db.Lobbies.Include(l => l.Members).FirstOrDefaultAsync(l => l.Id == id, cancellationToken);

    public Task<Lobby?> GetByAccountIdAsync(Guid accountId, CancellationToken cancellationToken = default)
        => db.Lobbies
            .Include(l => l.Members)
            .FirstOrDefaultAsync(l => l.Members.Any(m => m.AccountId == accountId), cancellationToken);

    public Task<List<Lobby>> ListOpenAsync(int limit = 20, CancellationToken cancellationToken = default)
        => db.Lobbies.Include(l => l.Members).OrderByDescending(l => l.CreatedAt).Take(limit).ToListAsync(cancellationToken);

    public Task<List<Lobby>> ListStaleAsync(DateTimeOffset threshold, CancellationToken cancellationToken = default)
        => db.Lobbies.Include(l => l.Members).Where(l => l.CreatedAt < threshold).ToListAsync(cancellationToken);

    public async Task<int> RemoveStaleAsync(DateTimeOffset threshold, CancellationToken cancellationToken = default)
    {
        var stale = await db.Lobbies.Where(l => l.CreatedAt < threshold).ToListAsync(cancellationToken);
        if (stale.Count == 0) return 0;
        db.Lobbies.RemoveRange(stale);
        await db.SaveChangesAsync(cancellationToken);
        return stale.Count;
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken = default)
        => db.SaveChangesAsync(cancellationToken);

    public void RemoveMember(LobbyMember member)
        => db.LobbyMembers.Remove(member);

    public void RemoveLobby(Lobby lobby)
        => db.Lobbies.Remove(lobby);
}
