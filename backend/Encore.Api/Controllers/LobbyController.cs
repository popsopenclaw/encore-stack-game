using System.IdentityModel.Tokens.Jwt;
using Encore.Application.Contracts.Lobby;
using Encore.Application.Lobby;
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
            return BadRequest(new { error = ex.Message });
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
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{code}")]
    public async Task<IActionResult> Get(string code)
    {
        var lobby = await lobbyUseCase.GetAsync(code);
        return lobby is null ? NotFound() : Ok(lobby);
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
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { error = ex.Message });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
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
        // for integration/test auth fallback
        return Guid.Parse("11111111-1111-1111-1111-111111111111");
    }
}
