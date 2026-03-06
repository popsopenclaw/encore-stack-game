using Encore.Application.Auth;
using Encore.Application.Contracts.Auth;
using Encore.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(IAuthUseCase authUseCase) : ControllerBase
{
    [HttpGet("providers")]
    public ActionResult<AuthProvidersResponse> GetProviders()
        => Ok(authUseCase.GetProviders());

    [HttpGet("oauth/{provider}/url")]
    public IActionResult GetOAuthLoginUrl([FromRoute] string provider, [FromQuery] string? state = null)
    {
        var url = authUseCase.BuildOAuthLoginUrl(provider, state);
        return Ok(new { url });
    }

    [HttpPost("oauth/{provider}/exchange")]
    public async Task<ActionResult<AuthResponse>> ExchangeOAuthCode(
        [FromRoute] string provider,
        [FromBody] OAuthExchangeRequest request,
        CancellationToken cancellationToken)
        => Ok(await authUseCase.ExchangeOAuthCodeAsync(provider, request.Code, cancellationToken));

    [HttpPost("local/login")]
    public async Task<ActionResult<AuthResponse>> LoginLocal([FromBody] LocalAuthRequest request, CancellationToken cancellationToken)
        => Ok(await authUseCase.LoginLocalAsync(request.Email, request.Password, cancellationToken));

    [HttpPost("local/register")]
    public async Task<ActionResult<AuthResponse>> RegisterLocal([FromBody] LocalAuthRequest request, CancellationToken cancellationToken)
        => Ok(await authUseCase.RegisterLocalAsync(request.Email, request.Password, cancellationToken));

    [Authorize]
    [HttpPost("links/oauth/{provider}/exchange")]
    public async Task<IActionResult> LinkOAuth(
        [FromRoute] string provider,
        [FromBody] OAuthExchangeRequest request,
        CancellationToken cancellationToken)
    {
        await authUseCase.LinkOAuthAsync(User.GetRequiredAccountId(), provider, request.Code, cancellationToken);
        return NoContent();
    }

    [Authorize]
    [HttpPost("links/local")]
    public async Task<IActionResult> LinkLocal([FromBody] LocalAuthRequest request, CancellationToken cancellationToken)
    {
        await authUseCase.LinkLocalAsync(User.GetRequiredAccountId(), request.Email, request.Password, cancellationToken);
        return NoContent();
    }
}
