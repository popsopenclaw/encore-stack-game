using Encore.Domain;
using Encore.Application.Abstractions;

namespace Encore.Application.Gameplay;

public class GameplayUseCase(IGameplayRepository repository, IGameRules rules) : IGameplayUseCase
{
    public async Task<GameState> StartAsync(StartGameRequest request, CancellationToken cancellationToken = default)
    {
        if (request.PlayerNames.Count is < 1 or > 6)
            throw new InvalidOperationException("Player count must be 1..6");

        var state = rules.NewGame(request.PlayerNames);
        await repository.SaveAsync(state.SessionId, state);
        return state;
    }

    public Task<GameState?> GetAsync(string sessionId, CancellationToken cancellationToken = default)
        => repository.GetAsync(sessionId);

    public async Task<DiceRoll> RollAsync(string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await MustGetState(sessionId);
        rules.RollForTurn(state);
        await Save(sessionId, state);
        return state.CurrentRoll!;
    }

    public async Task<GameState> ActiveSelectAsync(string sessionId, ActiveSelectionRequest request, CancellationToken cancellationToken = default)
    {
        var state = await MustGetState(sessionId);
        rules.ActivePlayerSelect(state, request);
        await Save(sessionId, state);
        return state;
    }

    public async Task<DiceRoll> GetAvailableDiceAsync(string sessionId, int playerIndex, CancellationToken cancellationToken = default)
    {
        var state = await MustGetState(sessionId);
        return rules.GetAvailableDiceForPlayer(state, playerIndex);
    }

    public async Task<GameState> PlayerActionAsync(string sessionId, PlayerActionRequest request, CancellationToken cancellationToken = default)
    {
        var state = await MustGetState(sessionId);
        rules.ResolvePlayerAction(state, request);
        await Save(sessionId, state);
        return state;
    }

    public async Task<GameState> EnableEncoreAsync(string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await MustGetState(sessionId);
        rules.EnableEncore(state);
        await Save(sessionId, state);
        return state;
    }

    public async Task<List<object>?> ScoreAsync(string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await repository.GetAsync(sessionId);
        return state is null ? null : rules.CalculateScores(state);
    }

    public async Task<List<TurnEvent>?> EventsAsync(string sessionId, CancellationToken cancellationToken = default)
    {
        var state = await repository.GetAsync(sessionId);
        return state?.Events;
    }

    public async Task<GameState> LegacyMoveAsync(string sessionId, MoveRequest move, CancellationToken cancellationToken = default)
    {
        var state = await MustGetState(sessionId);
        rules.ApplyMoveDirect(state, move);
        await Save(sessionId, state);
        return state;
    }

    private async Task<GameState> MustGetState(string sessionId)
        => await repository.GetAsync(sessionId)
           ?? throw new KeyNotFoundException("Game session not found");

    private async Task Save(string sessionId, GameState state)
        => await repository.SaveAsync(sessionId, state);
}
