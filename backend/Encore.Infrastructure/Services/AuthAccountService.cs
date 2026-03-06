using Encore.Application.Abstractions;
using Encore.Application.Contracts.Auth;
using Encore.Application.Profile;
using Encore.Domain.Models;
using Encore.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Encore.Infrastructure.Services;

public class AuthAccountService(
    AppDbContext dbContext,
    IEnumerable<IOAuthProviderService> oauthProviders,
    IPlayerNameGenerator playerNameGenerator,
    PasswordHasherService passwordHasher)
{
    private static readonly AuthProviderDto LocalProvider = new("local", "Email", "credentials");

    public IReadOnlyList<AuthProviderDto> GetProviders()
        => oauthProviders
            .Select(provider => new AuthProviderDto(provider.Id, provider.Label, "oauth"))
            .OrderBy(provider => provider.Label)
            .Append(LocalProvider)
            .ToList();

    public string BuildAuthorizeUrl(string provider, string? state)
        => GetProvider(provider).BuildAuthorizeUrl(state);

    public async Task<Account> ExchangeCodeAsync(string provider, string code, CancellationToken cancellationToken)
    {
        var identity = await GetProvider(provider).ExchangeCodeAsync(code, cancellationToken);
        var existingLink = await dbContext.AccountLinks
            .Include(link => link.Account)
            .FirstOrDefaultAsync(
                link => link.Provider == identity.Provider && link.ExternalId == identity.ExternalId,
                cancellationToken);

        if (existingLink is not null)
        {
            existingLink.Account.AvatarUrl = identity.AvatarUrl;
            existingLink.Account.UpdatedAt = DateTimeOffset.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
            return existingLink.Account;
        }

        var email = RequireEmail(identity.Email);
        var account = await dbContext.Accounts
            .FirstOrDefaultAsync(a => a.Email == email, cancellationToken);

        if (account is null)
        {
            account = await CreateAccountAsync(email, identity.AvatarUrl, cancellationToken);
            dbContext.Accounts.Add(account);
        }
        else
        {
            account.AvatarUrl = identity.AvatarUrl;
            account.UpdatedAt = DateTimeOffset.UtcNow;
        }

        dbContext.AccountLinks.Add(new AccountLink
        {
            Provider = identity.Provider,
            ExternalId = identity.ExternalId,
            AccountId = account.Id
        });

        await dbContext.SaveChangesAsync(cancellationToken);
        return account;
    }

    public async Task<Account> RegisterLocalAsync(string email, string password, CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(email);
        var account = await dbContext.Accounts.FirstOrDefaultAsync(a => a.Email == normalizedEmail, cancellationToken);
        if (account is not null)
            throw new InvalidOperationException("Email is already registered.");

        account = await CreateAccountAsync(normalizedEmail, string.Empty, cancellationToken);
        dbContext.Accounts.Add(account);

        var credential = passwordHasher.Hash(password);
        credential.AccountId = account.Id;
        dbContext.LocalAccountCredentials.Add(credential);
        dbContext.AccountLinks.Add(new AccountLink
        {
            Provider = "local",
            ExternalId = normalizedEmail,
            AccountId = account.Id
        });

        await dbContext.SaveChangesAsync(cancellationToken);
        return account;
    }

    public async Task<Account> LoginLocalAsync(string email, string password, CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(email);
        var account = await dbContext.AccountLinks
            .Where(link => link.Provider == "local" && link.ExternalId == normalizedEmail)
            .Select(link => link.Account)
            .Include(a => a.LocalCredential)
            .FirstOrDefaultAsync(cancellationToken);

        if (account?.LocalCredential is null || !passwordHasher.Verify(account.LocalCredential, password))
            throw new InvalidOperationException("Email or password is incorrect.");

        account.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return account;
    }

    public async Task LinkOAuthAsync(Guid accountId, string provider, string code, CancellationToken cancellationToken)
    {
        var account = await RequireAccountAsync(accountId, cancellationToken);
        var identity = await GetProvider(provider).ExchangeCodeAsync(code, cancellationToken);
        var existingProviderLink = await dbContext.AccountLinks
            .FirstOrDefaultAsync(link => link.Provider == identity.Provider && link.AccountId == accountId, cancellationToken);
        if (existingProviderLink is not null)
        {
            if (string.Equals(existingProviderLink.ExternalId, identity.ExternalId, StringComparison.Ordinal))
                return;

            throw new InvalidOperationException($"Provider '{identity.Provider}' is already linked to this account.");
        }

        await EnsureLinkAvailableAsync(identity.Provider, identity.ExternalId, accountId, cancellationToken);

        dbContext.AccountLinks.Add(new AccountLink
        {
            Provider = identity.Provider,
            ExternalId = identity.ExternalId,
            AccountId = accountId
        });

        if (!string.IsNullOrWhiteSpace(identity.AvatarUrl))
            account.AvatarUrl = identity.AvatarUrl;

        account.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task LinkLocalAsync(Guid accountId, string email, string password, CancellationToken cancellationToken)
    {
        var account = await RequireAccountAsync(accountId, cancellationToken);
        var normalizedEmail = NormalizeEmail(email);

        if (!string.Equals(account.Email, normalizedEmail, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Local login email must match the account email.");

        if (await dbContext.AccountLinks.AnyAsync(link => link.Provider == "local" && link.AccountId == accountId, cancellationToken))
            throw new InvalidOperationException("Local login is already linked.");

        await EnsureLinkAvailableAsync("local", normalizedEmail, accountId, cancellationToken);

        var credential = passwordHasher.Hash(password);
        credential.AccountId = accountId;
        dbContext.LocalAccountCredentials.Add(credential);
        dbContext.AccountLinks.Add(new AccountLink
        {
            Provider = "local",
            ExternalId = normalizedEmail,
            AccountId = accountId
        });

        account.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<Account> CreateAccountAsync(string email, string avatarUrl, CancellationToken cancellationToken)
    {
        var username = await GenerateUniqueUsernameAsync(cancellationToken);
        var playerName = await GenerateUniquePlayerNameAsync(cancellationToken);
        return new Account
        {
            Email = email,
            Username = username,
            PlayerName = playerName,
            NormalizedPlayerName = PlayerNamePolicy.Normalize(playerName),
            AvatarUrl = avatarUrl,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
    }

    private async Task<string> GenerateUniqueUsernameAsync(CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < 32; attempt++)
        {
            var candidate = playerNameGenerator.GenerateCandidate().ToLowerInvariant();
            var exists = await dbContext.Accounts.AnyAsync(a => a.Username == candidate, cancellationToken);
            if (!exists)
                return candidate;
        }

        throw new InvalidOperationException("Could not generate a unique username.");
    }

    private async Task<string> GenerateUniquePlayerNameAsync(CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < 32; attempt++)
        {
            var candidate = playerNameGenerator.GenerateCandidate();
            var normalized = PlayerNamePolicy.Normalize(candidate);
            var exists = await dbContext.Accounts.AnyAsync(a => a.NormalizedPlayerName == normalized, cancellationToken);
            if (!exists)
                return candidate;
        }

        throw new InvalidOperationException("Could not generate a unique player name.");
    }

    private async Task EnsureLinkAvailableAsync(string provider, string externalId, Guid accountId, CancellationToken cancellationToken)
    {
        var conflicting = await dbContext.AccountLinks
            .AnyAsync(link => link.Provider == provider && link.ExternalId == externalId && link.AccountId != accountId, cancellationToken);
        if (conflicting)
            throw new InvalidOperationException("That provider identity is already linked to another account.");
    }

    private async Task<Account> RequireAccountAsync(Guid accountId, CancellationToken cancellationToken)
        => await dbContext.Accounts.FirstOrDefaultAsync(a => a.Id == accountId, cancellationToken)
            ?? throw new InvalidOperationException("Account not found.");

    private IOAuthProviderService GetProvider(string provider)
        => oauthProviders.FirstOrDefault(p => p.Id == provider.Trim().ToLowerInvariant())
            ?? throw new InvalidOperationException($"Unsupported auth provider '{provider}'.");

    private static string RequireEmail(string? email)
    {
        var normalized = NormalizeEmail(email);
        if (string.IsNullOrWhiteSpace(normalized))
            throw new InvalidOperationException("The provider did not return an email address.");

        return normalized;
    }

    private static string NormalizeEmail(string? email)
    {
        var value = email?.Trim().ToLowerInvariant() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(value))
            return string.Empty;

        return value;
    }
}
