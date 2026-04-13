using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;

public sealed record GetAnalyticsOverviewQuery(int RecentActivityTake = 10) : IQuery<AnalyticsOverviewResponse>;
