using LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;

namespace LibroSphere.Application.Abstractions.Analytics;

public interface IAnalyticsService
{
    Task<AnalyticsOverviewResponse> GetOverviewAsync(int recentActivityTake, CancellationToken cancellationToken = default);
}
