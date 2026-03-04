using Encore.Domain;
using Encore.Application.Gameplay;
using Encore.Api.Middleware;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class GameplayController(IGameplayUseCase gameplay) : ControllerBase
{
    [HttpPost("start")]
    public async Task<IActionResult> Start([FromBody] StartGameRequest req)
    {
        try
        {
            var state = await gameplay.StartAsync(req);
            return Ok(state);
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }

    [HttpGet("{sessionId}")]
    public async Task<IActionResult> Get(string sessionId)
    {
        var state = await gameplay.GetAsync(sessionId);
        return state is null
            ? NotFound(ApiErrorFactory.Create("not_found", "Game session not found", HttpContext))
            : Ok(state);
    }

    [HttpPost("{sessionId}/roll")]
    public async Task<IActionResult> Roll(string sessionId)
    {
        try
        {
            var roll = await gameplay.RollAsync(sessionId);
            return Ok(roll);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }

    [HttpPost("{sessionId}/active-select")]
    public async Task<IActionResult> ActiveSelect(string sessionId, [FromBody] ActiveSelectionRequest request)
    {
        try
        {
            var state = await gameplay.ActiveSelectAsync(sessionId, request);
            return Ok(state);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }

    [HttpGet("{sessionId}/available-dice/{playerIndex:int}")]
    public async Task<IActionResult> AvailableDice(string sessionId, int playerIndex)
    {
        try
        {
            var dice = await gameplay.GetAvailableDiceAsync(sessionId, playerIndex);
            return Ok(dice);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }

    [HttpPost("{sessionId}/action")]
    public async Task<IActionResult> Action(string sessionId, [FromBody] PlayerActionRequest request)
    {
        try
        {
            var state = await gameplay.PlayerActionAsync(sessionId, request);
            return Ok(state);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }

    [HttpPost("{sessionId}/encore")]
    public async Task<IActionResult> EnableEncore(string sessionId)
    {
        try
        {
            var state = await gameplay.EnableEncoreAsync(sessionId);
            return Ok(state);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }

    [HttpGet("{sessionId}/score")]
    public async Task<IActionResult> Score(string sessionId)
    {
        var score = await gameplay.ScoreAsync(sessionId);
        return score is null
            ? NotFound(ApiErrorFactory.Create("not_found", "Game session not found", HttpContext))
            : Ok(score);
    }

    [HttpGet("{sessionId}/events")]
    public async Task<IActionResult> Events(string sessionId)
    {
        var eventsList = await gameplay.EventsAsync(sessionId);
        return eventsList is null
            ? NotFound(ApiErrorFactory.Create("not_found", "Game session not found", HttpContext))
            : Ok(eventsList);
    }

    [HttpPost("{sessionId}/move")]
    public async Task<IActionResult> Move(string sessionId, [FromBody] MoveRequest move)
    {
        try
        {
            var state = await gameplay.LegacyMoveAsync(sessionId, move);
            return Ok(state);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }
}
