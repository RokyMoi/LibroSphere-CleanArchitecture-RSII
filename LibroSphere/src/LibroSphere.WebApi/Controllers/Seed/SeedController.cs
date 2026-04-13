using LibroSphere.Application.Abstractions.Seeding;
using LibroSphere.Application.Abstractions.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Seed;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = ApplicationRoles.Admin)]
public class SeedController : ControllerBase
{
    private readonly ISeedService _seedService;

    public SeedController(ISeedService seedService)
    {
        _seedService = seedService;
    }

    [HttpPost("genres")]
    public async Task<IActionResult> SeedGenres(CancellationToken cancellationToken)
    {
        var result = await _seedService.SeedGenresAsync(cancellationToken);
        return Ok(result);
    }

    [HttpPost("catalog")]
    public async Task<IActionResult> SeedCatalog(CancellationToken cancellationToken)
    {
        var result = await _seedService.SeedCatalogAsync(cancellationToken);
        return Ok(result);
    }
}
