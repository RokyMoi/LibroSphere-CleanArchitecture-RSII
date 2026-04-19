using LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;

namespace LibroSphere.Infrastructure.Services.Analytics.Calculations;

internal static class CommerceAnalyticsCalculation
{
    public static CommerceAnalyticsSummary Calculate(
        int totalOrders,
        int paidOrders,
        decimal totalRevenue,
        decimal revenueLast30Days,
        int totalLibraryBooksGranted)
    {
        return new CommerceAnalyticsSummary
        {
            TotalOrders = totalOrders,
            PaidOrders = paidOrders,
            TotalRevenue = decimal.Round(totalRevenue, 2),
            RevenueLast30Days = decimal.Round(revenueLast30Days, 2),
            TotalLibraryBooksGranted = totalLibraryBooksGranted
        };
    }
}
