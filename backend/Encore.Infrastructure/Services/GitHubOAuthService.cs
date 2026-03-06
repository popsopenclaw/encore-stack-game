using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace Encore.Infrastructure.Services;

public class GitHubOAuthService(
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration) : IOAuthProviderService
{
    public string Id => "github";
    public string Label => "GitHub";

    public string BuildAuthorizeUrl(string? state)
    {
        var clientId = configuration["GitHubOAuth:ClientId"] ?? throw new InvalidOperationException("Missing GitHub OAuth client id");
        var redirectUri = configuration["GitHubOAuth:RedirectUri"];
        var encodedState = Uri.EscapeDataString(state ?? Guid.NewGuid().ToString("N"));

        var baseUrl = $"https://github.com/login/oauth/authorize?client_id={Uri.EscapeDataString(clientId)}&scope=read:user%20user:email&state={encodedState}";
        if (string.IsNullOrWhiteSpace(redirectUri))
            return baseUrl;

        return $"{baseUrl}&redirect_uri={Uri.EscapeDataString(redirectUri)}";
    }

    public async Task<OAuthProviderIdentity> ExchangeCodeAsync(string code, CancellationToken cancellationToken)
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
        var githubId = userJson.RootElement.GetProperty("id").GetInt64().ToString();
        var avatarUrl = userJson.RootElement.GetProperty("avatar_url").GetString() ?? string.Empty;
        var email = userJson.RootElement.TryGetProperty("email", out var emailEl) ? emailEl.GetString() : null;
        if (string.IsNullOrWhiteSpace(email))
            email = await FetchPrimaryEmailAsync(http, accessToken, cancellationToken);

        return new OAuthProviderIdentity(Id, githubId, email, avatarUrl);
    }

    private static async Task<string?> FetchPrimaryEmailAsync(HttpClient http, string accessToken, CancellationToken cancellationToken)
    {
        using var emailReq = new HttpRequestMessage(HttpMethod.Get, "https://api.github.com/user/emails");
        emailReq.Headers.UserAgent.Add(new ProductInfoHeaderValue("EncoreApi", "1.0"));
        emailReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        using var emailRes = await http.SendAsync(emailReq, cancellationToken);
        emailRes.EnsureSuccessStatusCode();

        var emailJson = JsonDocument.Parse(await emailRes.Content.ReadAsStringAsync(cancellationToken));
        foreach (var item in emailJson.RootElement.EnumerateArray())
        {
            var isPrimary = item.TryGetProperty("primary", out var primaryEl) && primaryEl.GetBoolean();
            var isVerified = item.TryGetProperty("verified", out var verifiedEl) && verifiedEl.GetBoolean();
            if (!isPrimary || !isVerified)
                continue;

            if (item.TryGetProperty("email", out var emailEl))
                return emailEl.GetString();
        }

        foreach (var item in emailJson.RootElement.EnumerateArray())
        {
            var isVerified = item.TryGetProperty("verified", out var verifiedEl) && verifiedEl.GetBoolean();
            if (!isVerified)
                continue;

            if (item.TryGetProperty("email", out var emailEl))
                return emailEl.GetString();
        }

        return null;
    }
}
