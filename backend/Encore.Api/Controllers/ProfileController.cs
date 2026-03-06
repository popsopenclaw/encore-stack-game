using System.IdentityModel.Tokens.Jwt;
using Encore.Application.Contracts.Profile;
using Encore.Application.Profile;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Encore.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/profile")]
public class ProfileController(IProfileUseCase profileUseCase) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ProfileDto>> Get(CancellationToken cancellationToken)
        => Ok(await profileUseCase.GetAsync(GetAccountId(), cancellationToken));

    [HttpPatch]
    public async Task<ActionResult<ProfileDto>> Update(
        [FromBody] UpdateProfileRequest request,
        CancellationToken cancellationToken)
        => Ok(await profileUseCase.UpdateAsync(GetAccountId(), request, cancellationToken));

    private Guid GetAccountId()
    {
        var sub = User.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub)?.Value;
        if (Guid.TryParse(sub, out var id)) return id;
        throw new UnauthorizedAccessException("Missing sub claim.");
    }
}
