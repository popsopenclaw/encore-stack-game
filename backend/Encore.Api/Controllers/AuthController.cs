using Encore.Api.Contracts.Auth;
using Encore.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(GitHubOAuthService gitHubOAuthService, JwtTokenService jwtTokenService) : ControllerBase
{
    [HttpGet("github/url")]
    public IActionResult GetGitHubLoginUrl([FromQuery] string? state = null)
    {
        var url = gitHubOAuthService.BuildAuthorizeUrl(state);
        return Ok(new { url });
    }

    [HttpPost("github/exchange")]
    public async Task<ActionResult<AuthResponse>> ExchangeGithubCode([FromBody] GithubExchangeRequest request, CancellationToken cancellationToken)
    {
        var account = await gitHubOAuthService.ExchangeCodeAndUpsertAsync(request.Code, cancellationToken);
        var token = jwtTokenService.CreateToken(account);

        return Ok(new AuthResponse(token, account.Username, account.Email, account.AvatarUrl));
    }
}
