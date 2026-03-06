using Encore.Domain;
using Encore.Application.Gameplay;
using Encore.Api.Middleware;
using Encore.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class GameplayController(IGameplayUseCase gameplay) : ControllerBase
{
    [HttpGet("{sessionId}")]
    public async Task<IActionResult> Get(string sessionId)
    {
        try
        {
            var state = await gameplay.GetAsync(User.GetRequiredAccountId(), sessionId);
            return state is null
                ? NotFound(ApiErrorFactory.Create("not_found", "Game session not found", HttpContext))
                : Ok(state);
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiErrorFactory.Create("forbidden", ex.Message, HttpContext));
        }
    }

    [HttpPost("{sessionId}/roll")]
    public async Task<IActionResult> Roll(string sessionId)
    {
        try
        {
            var roll = await gameplay.RollAsync(User.GetRequiredAccountId(), sessionId);
            return Ok(roll);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiErrorFactory.Create("forbidden", ex.Message, HttpContext));
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
            var state = await gameplay.ActiveSelectAsync(User.GetRequiredAccountId(), sessionId, request);
            return Ok(state);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiErrorFactory.Create("forbidden", ex.Message, HttpContext));
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
            var dice = await gameplay.GetAvailableDiceAsync(User.GetRequiredAccountId(), sessionId, playerIndex);
            return Ok(dice);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiErrorFactory.Create("forbidden", ex.Message, HttpContext));
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
            var state = await gameplay.PlayerActionAsync(User.GetRequiredAccountId(), sessionId, request);
            return Ok(state);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiErrorFactory.Create("forbidden", ex.Message, HttpContext));
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
            var state = await gameplay.EnableEncoreAsync(User.GetRequiredAccountId(), sessionId);
            return Ok(state);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiErrorFactory.Create("not_found", ex.Message, HttpContext));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiErrorFactory.Create("forbidden", ex.Message, HttpContext));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }

    [HttpGet("{sessionId}/score")]
    public async Task<IActionResult> Score(string sessionId)
    {
        try
        {
            var score = await gameplay.ScoreAsync(User.GetRequiredAccountId(), sessionId);
            return score is null
                ? NotFound(ApiErrorFactory.Create("not_found", "Game session not found", HttpContext))
                : Ok(score);
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiErrorFactory.Create("forbidden", ex.Message, HttpContext));
        }
    }

    [HttpGet("{sessionId}/events")]
    public async Task<IActionResult> Events(string sessionId)
    {
        try
        {
            var eventsList = await gameplay.EventsAsync(User.GetRequiredAccountId(), sessionId);
            return eventsList is null
                ? NotFound(ApiErrorFactory.Create("not_found", "Game session not found", HttpContext))
                : Ok(eventsList);
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, ApiErrorFactory.Create("forbidden", ex.Message, HttpContext));
        }
    }
}
