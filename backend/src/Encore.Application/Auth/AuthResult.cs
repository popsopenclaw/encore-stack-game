namespace Encore.Application.Auth;

public record AuthResult(string AccessToken, string Username, string? Email, string AvatarUrl);
