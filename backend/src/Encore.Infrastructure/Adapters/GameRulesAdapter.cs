using Encore.Api.Domain;
using Encore.Api.Services;
using Encore.Application.Abstractions;

namespace Encore.Infrastructure.Adapters;

public class GameRulesAdapter(EncoreRulesEngine rules) : IGameRules
{
    public GameState NewGame(List<string> playerNames) => rules.NewGame(playerNames);
    public void RollForTurn(GameState state) => rules.RollForTurn(state);
    public void ActivePlayerSelect(GameState state, ActiveSelectionRequest request) => rules.ActivePlayerSelect(state, request);
    public DiceRoll GetAvailableDiceForPlayer(GameState state, int playerIndex) => rules.GetAvailableDiceForPlayer(state, playerIndex);
    public void ResolvePlayerAction(GameState state, PlayerActionRequest request) => rules.ResolvePlayerAction(state, request);
    public void EnableEncore(GameState state) => rules.EnableEncore(state);
    public List<object> CalculateScores(GameState state) => rules.CalculateScores(state);
    public void ApplyMoveDirect(GameState state, MoveRequest move) => rules.ApplyMoveDirect(state, move);
}
