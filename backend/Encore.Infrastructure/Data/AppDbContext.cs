using Encore.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace Encore.Infrastructure.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<AccountLink> AccountLinks => Set<AccountLink>();
    public DbSet<LocalAccountCredential> LocalAccountCredentials => Set<LocalAccountCredential>();
    public DbSet<Lobby> Lobbies => Set<Lobby>();
    public DbSet<LobbyMember> LobbyMembers => Set<LobbyMember>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("citext");

        modelBuilder.Entity<Account>()
            .HasIndex(a => a.Username)
            .IsUnique();

        modelBuilder.Entity<Account>()
            .HasIndex(a => a.Email)
            .IsUnique();

        modelBuilder.Entity<Account>()
            .HasIndex(a => a.NormalizedPlayerName)
            .IsUnique();

        modelBuilder.Entity<Account>()
            .Property(a => a.Username)
            .HasColumnType("citext");

        modelBuilder.Entity<Account>()
            .Property(a => a.Email)
            .HasColumnType("citext");

        modelBuilder.Entity<Account>()
            .Property(a => a.PlayerName)
            .HasMaxLength(Encore.Application.Profile.PlayerNamePolicy.MaxLength);

        modelBuilder.Entity<Account>()
            .Property(a => a.NormalizedPlayerName)
            .HasMaxLength(Encore.Application.Profile.PlayerNamePolicy.MaxLength);

        modelBuilder.Entity<AccountLink>()
            .HasKey(l => new { l.Provider, l.ExternalId });

        modelBuilder.Entity<AccountLink>()
            .HasIndex(l => new { l.Provider, l.AccountId })
            .IsUnique();

        modelBuilder.Entity<AccountLink>()
            .Property(l => l.Provider)
            .HasMaxLength(32);

        modelBuilder.Entity<Account>()
            .HasMany(a => a.Links)
            .WithOne(l => l.Account)
            .HasForeignKey(l => l.AccountId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<LocalAccountCredential>()
            .HasKey(c => c.AccountId);

        modelBuilder.Entity<Account>()
            .HasOne(a => a.LocalCredential)
            .WithOne(c => c.Account)
            .HasForeignKey<LocalAccountCredential>(c => c.AccountId)
            .OnDelete(DeleteBehavior.Cascade);

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

        modelBuilder.Entity<LobbyMember>()
            .HasIndex(m => m.AccountId)
            .IsUnique();

        modelBuilder.Entity<Lobby>()
            .HasMany(l => l.Members)
            .WithOne(m => m.Lobby)
            .HasForeignKey(m => m.LobbyId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
