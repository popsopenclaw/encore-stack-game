using Encore.Application.Gameplay;
using Encore.Domain;

namespace Encore.Api.IntegrationTests.Fakes;

public class FakeGameplayUseCase : IGameplayUseCase
{
    private static readonly Guid PlayerOne = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private static readonly Guid PlayerTwo = Guid.Parse("22222222-2222-2222-2222-222222222222");

    public Task<GameState?> GetAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
        => Task.FromResult<GameState?>(EnsureParticipant(accountId, BuildState(sessionId)));

    public Task<DiceRoll> RollAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
        => Task.FromResult(EnsureOwnPlayer(accountId, 0, new DiceRoll([ColorDieFace.Blue], [NumberDieFace.Three])));

    public Task<GameState> ActiveSelectAsync(Guid accountId, string sessionId, ActiveSelectionRequest request, CancellationToken cancellationToken = default)
        => Task.FromResult(EnsureOwnPlayer(accountId, request.PlayerIndex, BuildState(sessionId)));

    public Task<DiceRoll> GetAvailableDiceAsync(Guid accountId, string sessionId, int playerIndex, CancellationToken cancellationToken = default)
        => Task.FromResult(EnsureOwnPlayer(accountId, playerIndex, new DiceRoll([ColorDieFace.Green], [NumberDieFace.One])));

    public Task<GameState> PlayerActionAsync(Guid accountId, string sessionId, PlayerActionRequest request, CancellationToken cancellationToken = default)
        => Task.FromResult(EnsureOwnPlayer(accountId, request.PlayerIndex, BuildState(sessionId)));

    public Task<GameState> EnableEncoreAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
        => Task.FromResult(EnsureParticipant(accountId, BuildState(sessionId)));

    public Task<List<object>?> ScoreAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
    {
        EnsureParticipant(accountId, BuildState(sessionId));
        return Task.FromResult<List<object>?>([
            new
            {
                player = "tester",
                columns = 0,
                colors = 0,
                jokerBonus = 8,
                tiebreakExclamationMarks = 8,
                starPenalty = 0,
                total = 8,
                rank = 1,
                isWinner = true
            }
        ]);
    }

    public Task<List<TurnEvent>?> EventsAsync(Guid accountId, string sessionId, CancellationToken cancellationToken = default)
    {
        EnsureParticipant(accountId, BuildState(sessionId));
        return Task.FromResult<List<TurnEvent>?>([new TurnEvent { Turn = 1, Type = "roll" }]);
    }

    private static GameState BuildState(string sessionId)
        => new()
        {
            SessionId = sessionId,
            ActivePlayerIndex = 0,
            Phase = TurnPhase.PlayersResolving,
            Players =
            [
                new PlayerState { AccountId = PlayerOne, Name = "player-1" },
                new PlayerState { AccountId = PlayerTwo, Name = "player-2" }
            ],
            Board = []
        };

    private static T EnsureParticipant<T>(Guid accountId, T value)
    {
        if (accountId != PlayerOne && accountId != PlayerTwo)
            throw new UnauthorizedAccessException("You do not have access to this game session.");
        return value;
    }

    private static T EnsureOwnPlayer<T>(Guid accountId, int playerIndex, T value)
    {
        if ((playerIndex == 0 && accountId != PlayerOne) ||
            (playerIndex == 1 && accountId != PlayerTwo))
            throw new UnauthorizedAccessException("You can only act on your own board.");
        return value;
    }
}
