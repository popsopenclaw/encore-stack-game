namespace Encore.Api.Contracts.Game;

public record CreateSessionRequest(string? Name, string? InitialStateJson);
