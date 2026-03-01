using Encore.Api.Contracts.Auth;
using Encore.Application.Auth;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(IAuthUseCase authUseCase) : ControllerBase
{
    [HttpGet("github/url")]
    public IActionResult GetGitHubLoginUrl([FromQuery] string? state = null)
    {
        var url = authUseCase.BuildGitHubLoginUrl(state);
        return Ok(new { url });
    }

    [HttpPost("github/exchange")]
    public async Task<ActionResult<AuthResponse>> ExchangeGithubCode([FromBody] GithubExchangeRequest request, CancellationToken cancellationToken)
    {
        var result = await authUseCase.ExchangeGitHubCodeAsync(request.Code, cancellationToken);
        var response = new AuthResponse(result.AccessToken, result.Username, result.Email, result.AvatarUrl);
        return Ok(response);
    }
}
