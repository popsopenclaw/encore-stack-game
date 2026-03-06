using Encore.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace Encore.Infrastructure.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<Lobby> Lobbies => Set<Lobby>();
    public DbSet<LobbyMember> LobbyMembers => Set<LobbyMember>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Account>()
            .HasIndex(a => a.GitHubId)
            .IsUnique();

        modelBuilder.Entity<Account>()
            .HasIndex(a => a.Username)
            .IsUnique();

        modelBuilder.Entity<Account>()
            .HasIndex(a => a.NormalizedPlayerName)
            .IsUnique();

        modelBuilder.Entity<Account>()
            .Property(a => a.PlayerName)
            .HasMaxLength(Encore.Application.Profile.PlayerNamePolicy.MaxLength);

        modelBuilder.Entity<Account>()
            .Property(a => a.NormalizedPlayerName)
            .HasMaxLength(Encore.Application.Profile.PlayerNamePolicy.MaxLength);

        modelBuilder.Entity<Lobby>()
            .HasIndex(l => l.Code)
            .IsUnique();

        modelBuilder.Entity<Lobby>()
            .Property(l => l.Code)
            .HasMaxLength(16);

        modelBuilder.Entity<Lobby>()
            .Property(l => l.ActiveSessionId)
            .HasMaxLength(64);

        modelBuilder.Entity<LobbyMember>()
            .HasIndex(m => new { m.LobbyId, m.AccountId })
            .IsUnique();

        modelBuilder.Entity<Lobby>()
            .HasMany(l => l.Members)
            .WithOne(m => m.Lobby)
            .HasForeignKey(m => m.LobbyId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
