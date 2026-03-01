using System.Net.Http.Headers;
using System.Text.Json;
using Encore.Api.Data;
using Encore.Api.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Encore.Api.Services;

public class GitHubOAuthService(IHttpClientFactory httpClientFactory, IConfiguration configuration, AppDbContext dbContext)
{
    public string BuildAuthorizeUrl(string? state)
    {
        var clientId = configuration["GitHubOAuth:ClientId"] ?? throw new InvalidOperationException("Missing GitHub OAuth client id");
        var redirectUri = configuration["GitHubOAuth:RedirectUri"] ?? throw new InvalidOperationException("Missing GitHub redirect uri");
        var encodedRedirect = Uri.EscapeDataString(redirectUri);
        var encodedState = Uri.EscapeDataString(state ?? Guid.NewGuid().ToString("N"));
        return $"https://github.com/login/oauth/authorize?client_id={clientId}&redirect_uri={encodedRedirect}&scope=read:user%20user:email&state={encodedState}";
    }

    public async Task<Account> ExchangeCodeAndUpsertAsync(string code, CancellationToken cancellationToken)
    {
        var clientId = configuration["GitHubOAuth:ClientId"] ?? throw new InvalidOperationException("Missing GitHubOAuth:ClientId");
        var clientSecret = configuration["GitHubOAuth:ClientSecret"] ?? throw new InvalidOperationException("Missing GitHubOAuth:ClientSecret");

        var http = httpClientFactory.CreateClient();

        using var tokenReq = new HttpRequestMessage(HttpMethod.Post, "https://github.com/login/oauth/access_token")
        {
            Content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["client_id"] = clientId,
                ["client_secret"] = clientSecret,
                ["code"] = code
            })
        };
        tokenReq.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

        using var tokenRes = await http.SendAsync(tokenReq, cancellationToken);
        tokenRes.EnsureSuccessStatusCode();

        var tokenJson = JsonDocument.Parse(await tokenRes.Content.ReadAsStringAsync(cancellationToken));
        var accessToken = tokenJson.RootElement.GetProperty("access_token").GetString()
                         ?? throw new InvalidOperationException("GitHub token missing");

        using var userReq = new HttpRequestMessage(HttpMethod.Get, "https://api.github.com/user");
        userReq.Headers.UserAgent.Add(new ProductInfoHeaderValue("EncoreApi", "1.0"));
        userReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        using var userRes = await http.SendAsync(userReq, cancellationToken);
        userRes.EnsureSuccessStatusCode();

        var userJson = JsonDocument.Parse(await userRes.Content.ReadAsStringAsync(cancellationToken));
        var githubId = userJson.RootElement.GetProperty("id").GetInt64();
        var username = userJson.RootElement.GetProperty("login").GetString() ?? "unknown";
        var avatarUrl = userJson.RootElement.GetProperty("avatar_url").GetString() ?? string.Empty;

        var email = userJson.RootElement.TryGetProperty("email", out var emailEl) ? emailEl.GetString() : null;

        var account = await dbContext.Accounts.FirstOrDefaultAsync(a => a.GitHubId == githubId, cancellationToken);
        if (account is null)
        {
            account = new Account
            {
                GitHubId = githubId,
                Username = username,
                Email = email,
                AvatarUrl = avatarUrl
            };
            dbContext.Accounts.Add(account);
        }
        else
        {
            account.Username = username;
            account.Email = email;
            account.AvatarUrl = avatarUrl;
            account.UpdatedAt = DateTimeOffset.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return account;
    }
}
