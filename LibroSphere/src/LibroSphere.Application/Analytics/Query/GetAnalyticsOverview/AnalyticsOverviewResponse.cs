using LibroSphere.Application.Abstractions.Analytics;

namespace LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;

public sealed class AnalyticsOverviewResponse
{
    public required CatalogAnalyticsSummary Catalog { get; init; }
    public required CommerceAnalyticsSummary Commerce { get; init; }
    public required EngagementAnalyticsSummary Engagement { get; init; }
    public required IReadOnlyCollection<AnalyticsActivityEntry> RecentActivity { get; init; }
}

public sealed class CatalogAnalyticsSummary
{
    public int TotalAuthors { get; init; }
    public int TotalBooks { get; init; }
    public int TotalGenres { get; init; }
    public decimal AverageBookPrice { get; init; }
    public double AverageReviewRating { get; init; }
}

public sealed class CommerceAnalyticsSummary
{
    public int TotalOrders { get; init; }
    public int PaidOrders { get; init; }
    public decimal TotalRevenue { get; init; }
    public decimal RevenueLast30Days { get; init; }
    public int TotalLibraryBooksGranted { get; init; }
}

public sealed class EngagementAnalyticsSummary
{
    public int TotalUsers { get; init; }
    public int ActiveUsers { get; init; }
    public int TotalReviews { get; init; }
    public int TotalWishlistItems { get; init; }
    public int UsersWithLast30DayLogin { get; init; }
}
