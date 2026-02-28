namespace Encore.Api.Contracts.Auth;

public record AuthResponse(string AccessToken, string Username, string? Email, string AvatarUrl);
