using Encore.Domain;
using Encore.Application.Abstractions;

namespace Encore.Application.Gameplay;

public class GameplayUseCase(IGameplayRepository repository, IGameRules rules) : IGameplayUseCase
{
    public async Task<GameState?> GetAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await repository.GetAsync(sessionId);
        if (state is null) return null;
        EnsureParticipant(state, accountId);
        return state;
    }

    public async Task<DiceRoll> RollAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await MustGetParticipantState(accountId, sessionId);
        EnsureAccountOwnsPlayer(state, accountId, state.ActivePlayerIndex, "Only the active player may roll.");
        rules.RollForTurn(state);
        await Save(sessionId, state);
        return state.CurrentRoll!;
    }

    public async Task<GameState> ActiveSelectAsync(Guid accountId, string sessionId, ActiveSelectionRequest request, CancellationToken cancellationToken = default)
    {
        var state = await MustGetParticipantState(accountId, sessionId);
        EnsureAccountOwnsPlayer(state, accountId, request.PlayerIndex, "You can only select dice for your own board.");
        rules.ActivePlayerSelect(state, request);
        await Save(sessionId, state);
        return state;
    }

    public async Task<DiceRoll> GetAvailableDiceAsync(Guid accountId, string sessionId, int playerIndex, CancellationToken cancellationToken = default)
    {
        var state = await MustGetParticipantState(accountId, sessionId);
        EnsureAccountOwnsPlayer(state, accountId, playerIndex, "You can only view dice for your own board.");
        return rules.GetAvailableDiceForPlayer(state, playerIndex);
    }

    public async Task<GameState> PlayerActionAsync(Guid accountId, string sessionId, PlayerActionRequest request, CancellationToken cancellationToken = default)
    {
        var state = await MustGetParticipantState(accountId, sessionId);
        EnsureAccountOwnsPlayer(state, accountId, request.PlayerIndex, "You can only act on your own board.");
        rules.ResolvePlayerAction(state, request);
        await Save(sessionId, state);
        return state;
    }

    public async Task<GameState> EnableEncoreAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await MustGetParticipantState(accountId, sessionId);
        rules.EnableEncore(state);
        await Save(sessionId, state);
        return state;
    }

    public async Task<List<object>?> ScoreAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await repository.GetAsync(sessionId);
        if (state is not null) EnsureParticipant(state, accountId);
        return state is null ? null : rules.CalculateScores(state);
    }

    public async Task<List<TurnEvent>?> EventsAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await repository.GetAsync(sessionId);
        if (state is not null) EnsureParticipant(state, accountId);
        return state?.Events;
    }

    private async Task<GameState> MustGetState(string sessionId)
        => await repository.GetAsync(sessionId)
           ?? throw new KeyNotFoundException("Game session not found");

    private async Task<GameState> MustGetParticipantState(Guid accountId, string sessionId)
    {
        var state = await MustGetState(sessionId);
        EnsureParticipant(state, accountId);
        return state;
    }

    private async Task Save(string sessionId, GameState state)
        => await repository.SaveAsync(sessionId, state);

    private static void EnsureParticipant(GameState state, Guid accountId)
    {
        if (!state.Players.Any(p => p.AccountId == accountId))
            throw new UnauthorizedAccessException("You do not have access to this game session.");
    }

    private static void EnsureAccountOwnsPlayer(GameState state, Guid accountId, int playerIndex, string message)
    {
        if (playerIndex < 0 || playerIndex >= state.Players.Count)
            throw new InvalidOperationException("Invalid player index.");
        if (state.Players[playerIndex].AccountId != accountId)
            throw new UnauthorizedAccessException(message);
    }
}
