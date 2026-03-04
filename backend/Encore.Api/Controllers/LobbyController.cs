using System.IdentityModel.Tokens.Jwt;
using Encore.Application.Contracts.Lobby;
using Encore.Application.Lobby;
using Encore.Api.Middleware;
using Encore.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class LobbyController(ILobbyUseCase lobbyUseCase, LobbyRealtimeNotifier notifier) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateLobbyRequest request)
    {
        try
        {
            var lobby = await lobbyUseCase.CreateAsync(GetAccountId(), request);
            await notifier.LobbyUpdatedAsync(lobby);
            return Ok(lobby);
        }
        catch (Exception ex)
        {
            return BadRequest(ApiErrorFactory.Create("invalid_request", ex.Message, HttpContext));
        }
    }

    [HttpPost("join")]
    public async Task<IActionResult> Join([FromBody] JoinLobbyRequest request)
    {
        try
        {
            var lobby = await lobbyUseCase.JoinAsync(GetAccountId(), request);
            await notifier.LobbyUpdatedAsync(lobby);
            return Ok(lobby);
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

    [HttpGet("{code}")]
    public async Task<IActionResult> Get(string code)
    {
        var lobby = await lobbyUseCase.GetAsync(code);
        return lobby is null
            ? NotFound(ApiErrorFactory.Create("not_found", "Lobby not found", HttpContext))
            : Ok(lobby);
    }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] int limit = 20)
        => Ok(await lobbyUseCase.ListAsync(limit));

    [HttpPatch("{code}")]
    public async Task<IActionResult> Update(string code, [FromBody] UpdateLobbyRequest request)
    {
        try
        {
            var lobby = await lobbyUseCase.UpdateAsync(GetAccountId(), code, request);
            await notifier.LobbyUpdatedAsync(lobby);
            return Ok(lobby);
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

    [HttpPost("{code}/start")]
    public async Task<IActionResult> StartMatch(string code, [FromBody] StartLobbyMatchRequest request)
    {
        try
        {
            var sessionId = await lobbyUseCase.StartMatchAsync(GetAccountId(), code, request);
            return Ok(new { sessionId });
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

    [HttpPost("{code}/leave")]
    public async Task<IActionResult> Leave(string code)
    {
        await lobbyUseCase.LeaveAsync(GetAccountId(), code);
        var lobby = await lobbyUseCase.GetAsync(code);
        if (lobby is not null) await notifier.LobbyUpdatedAsync(lobby);
        return NoContent();
    }

    private Guid GetAccountId()
    {
        var sub = User.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub)?.Value;
        if (Guid.TryParse(sub, out var id)) return id;
        return Guid.Parse("11111111-1111-1111-1111-111111111111");
    }
}
