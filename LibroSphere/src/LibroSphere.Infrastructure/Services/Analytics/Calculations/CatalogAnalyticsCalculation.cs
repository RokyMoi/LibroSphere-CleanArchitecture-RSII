using LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;

namespace LibroSphere.Infrastructure.Services.Analytics.Calculations;

internal static class CatalogAnalyticsCalculation
{
    public static CatalogAnalyticsSummary Calculate(
        int totalAuthors,
        int totalBooks,
        int totalGenres,
        decimal averageBookPrice,
        double averageReviewRating)
    {
        return new CatalogAnalyticsSummary
        {
            TotalAuthors = totalAuthors,
            TotalBooks = totalBooks,
            TotalGenres = totalGenres,
            AverageBookPrice = decimal.Round(averageBookPrice, 2),
            AverageReviewRating = Math.Round(averageReviewRating, 2)
        };
    }
}
