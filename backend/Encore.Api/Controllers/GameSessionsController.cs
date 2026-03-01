using System.IdentityModel.Tokens.Jwt;
using Encore.Infrastructure.Services;
using Encore.Application.Contracts.Game;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class GameSessionsController(GameSessionService gameSessionService) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateSessionRequest request)
    {
        var accountId = GetAccountId();
        var session = await gameSessionService.CreateAsync(accountId, request.Name, request.InitialStateJson);
        return Ok(session);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var session = await gameSessionService.GetAsync(id);
        return session is null ? NotFound() : Ok(session);
    }

    [HttpPut("{id}/state")]
    public async Task<IActionResult> UpdateState(string id, [FromBody] UpdateSessionRequest request)
    {
        var updated = await gameSessionService.UpdateStateAsync(id, request.StateJson);
        return updated is null ? NotFound() : Ok(updated);
    }

    private Guid GetAccountId()
    {
        var sub = User.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub)?.Value
                  ?? throw new UnauthorizedAccessException("Missing sub claim.");
        return Guid.Parse(sub);
    }
}
