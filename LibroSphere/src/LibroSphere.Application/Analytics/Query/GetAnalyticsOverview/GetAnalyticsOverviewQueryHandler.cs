using LibroSphere.Application.Abstractions.Analytics;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;

internal sealed class GetAnalyticsOverviewQueryHandler : IQueryHandler<GetAnalyticsOverviewQuery, AnalyticsOverviewResponse>
{
    private readonly IAnalyticsService _analyticsService;

    public GetAnalyticsOverviewQueryHandler(IAnalyticsService analyticsService)
    {
        _analyticsService = analyticsService;
    }

    public async Task<Result<AnalyticsOverviewResponse>> Handle(GetAnalyticsOverviewQuery request, CancellationToken cancellationToken)
    {
        var overview = await _analyticsService.GetOverviewAsync(request.RecentActivityTake, cancellationToken);
        return Result.Success(overview);
    }
}
