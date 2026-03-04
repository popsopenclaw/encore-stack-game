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

    public Task<List<Lobby>> ListOpenAsync(int limit = 20, CancellationToken cancellationToken = default)
        => db.Lobbies.Include(l => l.Members).OrderByDescending(l => l.CreatedAt).Take(limit).ToListAsync(cancellationToken);

    public Task SaveChangesAsync(CancellationToken cancellationToken = default)
        => db.SaveChangesAsync(cancellationToken);

    public void RemoveMember(LobbyMember member)
        => db.LobbyMembers.Remove(member);
}
