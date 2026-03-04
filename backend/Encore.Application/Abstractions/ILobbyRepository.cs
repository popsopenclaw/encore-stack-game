using Encore.Domain.Models;
using LobbyEntity = Encore.Domain.Models.Lobby;

namespace Encore.Application.Abstractions;

public interface ILobbyRepository
{
    Task<LobbyEntity> CreateAsync(LobbyEntity lobby, CancellationToken cancellationToken = default);
    Task<LobbyEntity?> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<LobbyEntity?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task SaveChangesAsync(CancellationToken cancellationToken = default);
    Task<List<LobbyEntity>> ListOpenAsync(int limit = 20, CancellationToken cancellationToken = default);
    void RemoveMember(LobbyMember member);
    void RemoveLobby(LobbyEntity lobby);
}