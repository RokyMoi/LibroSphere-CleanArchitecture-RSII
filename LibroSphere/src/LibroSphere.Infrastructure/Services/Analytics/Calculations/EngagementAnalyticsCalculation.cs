using LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;

namespace LibroSphere.Infrastructure.Services.Analytics.Calculations;

internal static class EngagementAnalyticsCalculation
{
    public static EngagementAnalyticsSummary Calculate(
        int totalUsers,
        int activeUsers,
        int totalReviews,
        int totalWishlistItems,
        int usersWithLast30DayLogin)
    {
        return new EngagementAnalyticsSummary
        {
            TotalUsers = totalUsers,
            ActiveUsers = activeUsers,
            TotalReviews = totalReviews,
            TotalWishlistItems = totalWishlistItems,
            UsersWithLast30DayLogin = usersWithLast30DayLogin
        };
    }
}
