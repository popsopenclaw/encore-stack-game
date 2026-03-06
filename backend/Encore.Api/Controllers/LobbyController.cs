using System.IdentityModel.Tokens.Jwt;
using Encore.Application;
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
            var accountId = User.GetRequiredAccountId();
            var lobby = await lobbyUseCase.CreateAsync(accountId, request);
            await notifier.LobbyUpdatedAsync(lobby);
            return Ok(EnrichForViewer(lobby, accountId));
        }
        catch (InvalidSessionException ex)
        {
            return Unauthorized(ApiErrorFactory.Create("invalid_session", ex.Message, HttpContext));
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
            var accountId = User.GetRequiredAccountId();
            var lobby = await lobbyUseCase.JoinAsync(accountId, request);
            await notifier.LobbyUpdatedAsync(lobby);
            return Ok(EnrichForViewer(lobby, accountId));
        }
        catch (InvalidSessionException ex)
        {
            return Unauthorized(ApiErrorFactory.Create("invalid_session", ex.Message, HttpContext));
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
        var accountId = User.GetRequiredAccountId();
        var lobby = await lobbyUseCase.GetAsync(code);
        return lobby is null
            ? NotFound(ApiErrorFactory.Create("not_found", "Lobby not found", HttpContext))
            : Ok(EnrichForViewer(lobby, accountId));
    }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] int limit = 20)
    {
        var accountId = User.GetRequiredAccountId();
        var lobbies = await lobbyUseCase.ListAsync(limit);
        return Ok(lobbies.Select(l => EnrichForViewer(l, accountId)).ToList());
    }

    [HttpPatch("{code}")]
    public async Task<IActionResult> Update(string code, [FromBody] UpdateLobbyRequest request)
    {
        try
        {
            var accountId = User.GetRequiredAccountId();
            var lobby = await lobbyUseCase.UpdateAsync(accountId, code, request);
            await notifier.LobbyUpdatedAsync(lobby);
            return Ok(EnrichForViewer(lobby, accountId));
        }
        catch (InvalidSessionException ex)
        {
            return Unauthorized(ApiErrorFactory.Create("invalid_session", ex.Message, HttpContext));
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
            var sessionId = await lobbyUseCase.StartMatchAsync(User.GetRequiredAccountId(), code, request);
            var lobby = await lobbyUseCase.GetAsync(code);
            if (lobby is not null) await notifier.LobbyUpdatedAsync(lobby);
            return Ok(new { sessionId });
        }
        catch (InvalidSessionException ex)
        {
            return Unauthorized(ApiErrorFactory.Create("invalid_session", ex.Message, HttpContext));
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
        await lobbyUseCase.LeaveAsync(User.GetRequiredAccountId(), code);
        var lobby = await lobbyUseCase.GetAsync(code);
        if (lobby is not null) await notifier.LobbyUpdatedAsync(lobby);
        return NoContent();
    }

    private static object EnrichForViewer(LobbyDto lobby, Guid viewerAccountId)
        => new
        {
            lobby.Id,
            lobby.Code,
            lobby.Name,
            lobby.MaxPlayers,
            lobby.HostAccountId,
            lobby.HostDisplayName,
            lobby.Members,
            lobby.ActiveSessionId,
            lobby.HasActiveGame,
            isHostForCurrentUser = lobby.HostAccountId == viewerAccountId
        };

}
