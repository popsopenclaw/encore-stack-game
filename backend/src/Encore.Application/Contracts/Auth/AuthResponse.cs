namespace Encore.Application.Contracts.Auth;

public record AuthResponse(string AccessToken, string Username, string? Email, string AvatarUrl);
