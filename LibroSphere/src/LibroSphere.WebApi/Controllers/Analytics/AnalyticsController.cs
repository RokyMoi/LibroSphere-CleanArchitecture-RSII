using LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;
using LibroSphere.Application.Abstractions.Identity;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Analytics;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = ApplicationRoles.Admin)]
public sealed class AnalyticsController : ControllerBase
{
    private readonly IMediator _mediator;

    public AnalyticsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("overview")]
    public async Task<IActionResult> GetOverview([FromQuery] int recentActivityTake = 10, CancellationToken cancellationToken = default)
    {
        var result = await _mediator.Send(new GetAnalyticsOverviewQuery(recentActivityTake), cancellationToken);
        return Ok(result.Value);
    }
}
