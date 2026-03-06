using Encore.Application.Abstractions;
using Encore.Domain.Models;
using Encore.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Encore.Infrastructure.Adapters;

public class AccountRepositoryAdapter(AppDbContext db) : IAccountRepository
{
    public Task<Account?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        => db.Accounts.FirstOrDefaultAsync(a => a.Id == id, cancellationToken);

    public Task<List<Account>> GetByIdsAsync(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken = default)
        => ids.Count == 0
            ? Task.FromResult(new List<Account>())
            : db.Accounts.Where(a => ids.Contains(a.Id)).ToListAsync(cancellationToken);

    public Task<bool> ExistsByNormalizedPlayerNameAsync(
        string normalizedPlayerName,
        Guid? excludeAccountId = null,
        CancellationToken cancellationToken = default)
        => db.Accounts.AnyAsync(
            a => a.NormalizedPlayerName == normalizedPlayerName &&
                (!excludeAccountId.HasValue || a.Id != excludeAccountId.Value),
            cancellationToken);

    public Task SaveChangesAsync(CancellationToken cancellationToken = default)
        => db.SaveChangesAsync(cancellationToken);
}
