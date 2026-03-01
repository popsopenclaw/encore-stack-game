using System.Text.Json;
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

        try
        {
            rules.RollForTurn(state);
            await gameSessionService.SaveStateAsync(sessionId, JsonSerializer.Serialize(state));
            return Ok(state.CurrentRoll);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{sessionId}/active-select")]
    public async Task<IActionResult> ActiveSelect(string sessionId, [FromBody] ActiveSelectionRequest request)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();

        try
        {
            rules.ActivePlayerSelect(state, request);
            await gameSessionService.SaveStateAsync(sessionId, JsonSerializer.Serialize(state));
            return Ok(state);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{sessionId}/available-dice/{playerIndex:int}")]
    public async Task<IActionResult> AvailableDice(string sessionId, int playerIndex)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();

        try
        {
            return Ok(rules.GetAvailableDiceForPlayer(state, playerIndex));
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{sessionId}/action")]
    public async Task<IActionResult> Action(string sessionId, [FromBody] PlayerActionRequest request)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();

        try
        {
            rules.ResolvePlayerAction(state, request);
            await gameSessionService.SaveStateAsync(sessionId, JsonSerializer.Serialize(state));
            return Ok(state);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{sessionId}/encore")]
    public async Task<IActionResult> EnableEncore(string sessionId)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();

        try
        {
            rules.EnableEncore(state);
            await gameSessionService.SaveStateAsync(sessionId, JsonSerializer.Serialize(state));
            return Ok(state);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{sessionId}/score")]
    public async Task<IActionResult> Score(string sessionId)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();
        return Ok(rules.CalculateScores(state));
    }

    // Legacy direct move endpoint kept for compatibility with earlier clients.
    [HttpPost("{sessionId}/move")]
    public async Task<IActionResult> Move(string sessionId, [FromBody] MoveRequest move)
    {
        var state = await gameSessionService.GetStateAsync<GameState>(sessionId);
        if (state is null) return NotFound();

        try
        {
            rules.ApplyMoveDirect(state, move);
            await gameSessionService.SaveStateAsync(sessionId, JsonSerializer.Serialize(state));
            return Ok(state);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
