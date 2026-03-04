using Encore.Application.Contracts.Lobby;

namespace Encore.Application.Lobby;

public interface ILobbyUseCase
{
    Task<LobbyDto> CreateAsync(Guid accountId, CreateLobbyRequest request, CancellationToken cancellationToken = default);
    Task<LobbyDto> JoinAsync(Guid accountId, JoinLobbyRequest request, CancellationToken cancellationToken = default);
    Task<LobbyDto?> GetAsync(string code, CancellationToken cancellationToken = default);
    Task<List<LobbyDto>> ListAsync(int limit = 20, CancellationToken cancellationToken = default);
    Task<LobbyDto> UpdateAsync(Guid accountId, string code, UpdateLobbyRequest request, CancellationToken cancellationToken = default);
    Task LeaveAsync(Guid accountId, string code, CancellationToken cancellationToken = default);
}