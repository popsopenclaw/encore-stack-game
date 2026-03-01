using Encore.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace Encore.Infrastructure.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Account> Accounts => Set<Account>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Account>()
            .HasIndex(a => a.GitHubId)
            .IsUnique();

        modelBuilder.Entity<Account>()
            .HasIndex(a => a.Username)
            .IsUnique();
    }
}
