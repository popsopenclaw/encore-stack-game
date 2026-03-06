using Encore.Application.Contracts.Profile;
using Encore.Application.Profile;
using Encore.Api.Services;
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
        => Ok(await profileUseCase.GetAsync(User.GetRequiredAccountId(), cancellationToken));

    [HttpPatch]
    public async Task<ActionResult<ProfileDto>> Update(
        [FromBody] UpdateProfileRequest request,
        CancellationToken cancellationToken)
        => Ok(await profileUseCase.UpdateAsync(User.GetRequiredAccountId(), request, cancellationToken));
}
