namespace Encore.Infrastructure.Services;

public interface IGameRulesEngine<TState>
{
    string GameKey { get; }
    TState NewGame(List<string> playerNames);
}
