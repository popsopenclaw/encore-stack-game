namespace Encore.Application.Contracts.Game;

public record CreateSessionRequest(string? Name, string? InitialStateJson);
