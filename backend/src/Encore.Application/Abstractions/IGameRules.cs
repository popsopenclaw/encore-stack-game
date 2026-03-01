using Encore.Api.Domain;

namespace Encore.Application.Abstractions;

public interface IGameRules
{
    GameState NewGame(List<string> playerNames);
    void RollForTurn(GameState state);
    void ActivePlayerSelect(GameState state, ActiveSelectionRequest request);
    DiceRoll GetAvailableDiceForPlayer(GameState state, int playerIndex);
    void ResolvePlayerAction(GameState state, PlayerActionRequest request);
    void EnableEncore(GameState state);
    List<object> CalculateScores(GameState state);
    void ApplyMoveDirect(GameState state, MoveRequest move);
}
