namespace Encore.Application.Contracts.Auth;

public record AuthProvidersResponse(IReadOnlyList<AuthProviderDto> Providers);
