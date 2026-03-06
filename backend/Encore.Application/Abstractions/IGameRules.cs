using Encore.Domain;

namespace Encore.Application.Abstractions;

public interface IGameRules
{
    GameState NewGame(List<GamePlayerSeed> players);
    void RollForTurn(GameState state);
    void ActivePlayerSelect(GameState state, ActiveSelectionRequest request);
    DiceRoll GetAvailableDiceForPlayer(GameState state, int playerIndex);
    void ResolvePlayerAction(GameState state, PlayerActionRequest request);
    void EnableEncore(GameState state);
    List<object> CalculateScores(GameState state);
}
