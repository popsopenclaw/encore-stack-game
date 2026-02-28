using System.Text.Json;
using Encore.Api.Contracts.Game;
using Encore.Api.Domain;
using Encore.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class GameplayController(GameSessionService gameSessionService, EncoreRulesEngine rules) : ControllerBase
{
    [HttpPost("start")]
    public async Task<IActionResult> Start([FromBody] StartGameRequest req)
    {
        if (req.PlayerNames.Count is < 1 or > 6) return BadRequest("Player count must be 1..6");
        var state = rules.NewGame(req.PlayerNames);
        await gameSessionService.SaveStateAsync(state.SessionId, JsonSerializer.Serialize(state));
        return Ok(state);
    }

    [HttpGet("{sessionId}")]
    public async Task<IActionResult> Get(string sessionId)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        return state is null ? NotFound() : Ok(state);
    }

    [HttpPost("{sessionId}/roll")]
    public async Task<IActionResult> Roll(string sessionId)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();

        var roll = rules.RollDice();
        await gameSessionService.SaveStateAsync(sessionId, JsonSerializer.Serialize(state));
        return Ok(roll);
    }

    [HttpGet("{sessionId}/score")]
    public async Task<IActionResult> Score(string sessionId)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();
        return Ok(rules.CalculateScores(state));
    }

    [HttpPost("{sessionId}/move")]
    public async Task<IActionResult> Move(string sessionId, [FromBody] MoveRequest move)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();

        try
        {
            rules.ApplyMove(state, move);
            await gameSessionService.SaveStateAsync(sessionId, JsonSerializer.Serialize(state));
            return Ok(state);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
