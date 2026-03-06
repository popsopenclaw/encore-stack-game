using Encore.Application.Abstractions;
using Encore.Application.Gameplay;
using Encore.Domain;

namespace Encore.Api.Tests;

public class GameplayUseCaseTests
{
    [Fact]
    public async Task GetAsync_RejectsNonParticipant()
    {
        var state = BuildState();
        var useCase = CreateUseCase(state);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            useCase.GetAsync(Guid.NewGuid(), state.SessionId));
    }

    [Fact]
    public async Task GetAvailableDiceAsync_RejectsOtherPlayersBoard()
    {
        var state = BuildState();
        var useCase = CreateUseCase(state);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            useCase.GetAvailableDiceAsync(state.Players[0].AccountId, state.SessionId, 1));
    }

    [Fact]
    public async Task PlayerActionAsync_UsesOwnedBoard()
    {
        var state = BuildState();
        var useCase = CreateUseCase(state);

        await useCase.PlayerActionAsync(
            state.Players[1].AccountId,
            state.SessionId,
            new PlayerActionRequest(1, ColorDieFace.Blue, NumberDieFace.One, ["c1"], false));

        Assert.Contains("c1", state.Players[1].CheckedCells);
    }

    [Fact]
    public async Task RollAsync_RejectsInactivePlayer()
    {
        var state = BuildState();
        var useCase = CreateUseCase(state);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            useCase.RollAsync(state.Players[1].AccountId, state.SessionId));
    }

    private static GameplayUseCase CreateUseCase(GameState state)
        => new(new FakeGameplayRepository(state), new FakeGameRules());

    private static GameState BuildState()
    {
        var first = Guid.NewGuid();
        var second = Guid.NewGuid();
        return new GameState
        {
            SessionId = Guid.NewGuid().ToString("N"),
            ActivePlayerIndex = 0,
            CurrentRoll = new DiceRoll([ColorDieFace.Blue], [NumberDieFace.One]),
            Phase = TurnPhase.PlayersResolving,
            Players =
            [
                new PlayerState { AccountId = first, Name = "first" },
                new PlayerState { AccountId = second, Name = "second" }
            ],
            Board = [new CellDef { Id = "c1", Color = CellColor.Blue, Column = "H" }]
        };
    }

    private sealed class FakeGameplayRepository(GameState state) : IGameplayRepository
    {
        public Task SaveAsync(string sessionId, GameState nextState)
            => Task.CompletedTask;

        public Task<GameState?> GetAsync(string sessionId)
            => Task.FromResult<GameState?>(state);
    }

    private sealed class FakeGameRules : IGameRules
    {
        public GameState NewGame(List<GamePlayerSeed> players) => throw new NotSupportedException();

        public void RollForTurn(GameState state)
        {
            state.CurrentRoll = new DiceRoll([ColorDieFace.Green], [NumberDieFace.Three]);
        }

        public void ActivePlayerSelect(GameState state, ActiveSelectionRequest request) { }

        public DiceRoll GetAvailableDiceForPlayer(GameState state, int playerIndex)
            => new([ColorDieFace.Blue], [NumberDieFace.One]);

        public void ResolvePlayerAction(GameState state, PlayerActionRequest request)
        {
            foreach (var cellId in request.CellIds ?? [])
                state.Players[request.PlayerIndex].CheckedCells.Add(cellId);
        }

        public void EnableEncore(GameState state) { }

        public List<object> CalculateScores(GameState state) => [];
    }
}
