namespace Encore.Application.Contracts.Profile;

public record ProfileDto(
    Guid Id,
    string PlayerName,
    string Username,
    string Email,
    string AvatarUrl);
