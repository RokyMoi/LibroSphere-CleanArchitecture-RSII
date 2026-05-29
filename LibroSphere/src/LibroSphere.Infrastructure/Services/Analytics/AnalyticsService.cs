using LibroSphere.Application.Abstractions.Analytics;
using LibroSphere.Application.Analytics.Query.GetAnalyticsOverview;
using LibroSphere.Domain.Entities.Authors;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Users;
using LibroSphere.Infrastructure.Services.Analytics.Calculations;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Services.Analytics;

internal sealed class AnalyticsService : IAnalyticsService
{
    private readonly IDbContextFactory<ApplicationDbContext> _dbContextFactory;
    private readonly IAnalyticsActivityStore _activityStore;

    public AnalyticsService(
        IDbContextFactory<ApplicationDbContext> dbContextFactory,
        IAnalyticsActivityStore activityStore)
    {
        _dbContextFactory = dbContextFactory;
        _activityStore = activityStore;
    }

    public async Task<AnalyticsOverviewResponse> GetOverviewAsync(int recentActivityTake, CancellationToken cancellationToken = default)
    {
        var cutoff = DateTime.UtcNow.AddDays(-30);

        var catalogTask = GetCatalogStatsAsync(cutoff, cancellationToken);
        var engagementTask = GetEngagementStatsAsync(cutoff, cancellationToken);
        var commerceTask = GetCommerceStatsAsync(cutoff, cancellationToken);
        var activityTask = _activityStore.GetRecentAsync(recentActivityTake, cancellationToken);

        await Task.WhenAll(catalogTask, engagementTask, commerceTask, activityTask);

        var (totalAuthors, totalBooks, totalGenres, averageBookPrice, averageReviewRating) = await catalogTask;
        var (totalUsers, activeUsers, totalReviews, totalWishlistItems, usersWithLast30DayLogin) = await engagementTask;
        var (totalOrders, paidOrders, totalRevenue, revenueLast30Days, totalLibraryBooksGranted) = await commerceTask;
        var recentActivity = await activityTask;

        return new AnalyticsOverviewResponse
        {
            Catalog = CatalogAnalyticsCalculation.Calculate(totalAuthors, totalBooks, totalGenres, averageBookPrice, averageReviewRating),
            Commerce = CommerceAnalyticsCalculation.Calculate(totalOrders, paidOrders, totalRevenue, revenueLast30Days, totalLibraryBooksGranted),
            Engagement = EngagementAnalyticsCalculation.Calculate(totalUsers, activeUsers, totalReviews, totalWishlistItems, usersWithLast30DayLogin),
            RecentActivity = recentActivity
        };
    }

    private async Task<(int TotalAuthors, int TotalBooks, int TotalGenres, decimal AverageBookPrice, double AverageReviewRating)>
        GetCatalogStatsAsync(DateTime cutoff, CancellationToken cancellationToken)
    {
        await using var db = await _dbContextFactory.CreateDbContextAsync(cancellationToken);

        var totalAuthors = await db.Set<Author>().CountAsync(cancellationToken);
        var totalBooks = await db.Set<Book>().CountAsync(cancellationToken);
        var totalGenres = await db.Set<Genre>().CountAsync(cancellationToken);
        var averageBookPrice = await db.Set<Book>().AverageAsync(x => (decimal?)x.Price.amount, cancellationToken) ?? 0m;
        var averageReviewRating = await db.Set<Review>().AverageAsync(x => (double?)x.Rating, cancellationToken) ?? 0d;

        return (totalAuthors, totalBooks, totalGenres, averageBookPrice, averageReviewRating);
    }

    private async Task<(int TotalUsers, int ActiveUsers, int TotalReviews, int TotalWishlistItems, int UsersWithLast30DayLogin)>
        GetEngagementStatsAsync(DateTime cutoff, CancellationToken cancellationToken)
    {
        await using var db = await _dbContextFactory.CreateDbContextAsync(cancellationToken);

        var totalUsers = await db.Set<User>().CountAsync(cancellationToken);
        var activeUsers = await db.Set<User>().CountAsync(x => x.IsActive, cancellationToken);
        var totalReviews = await db.Set<Review>().CountAsync(cancellationToken);
        var totalWishlistItems = await db.Set<WishlistItem>().CountAsync(cancellationToken);
        var usersWithLast30DayLogin = await db.Set<User>()
            .CountAsync(x => x.LastLogin.HasValue && x.LastLogin.Value >= cutoff, cancellationToken);

        return (totalUsers, activeUsers, totalReviews, totalWishlistItems, usersWithLast30DayLogin);
    }

    private async Task<(int TotalOrders, int PaidOrders, decimal TotalRevenue, decimal RevenueLast30Days, int TotalLibraryBooksGranted)>
        GetCommerceStatsAsync(DateTime cutoff, CancellationToken cancellationToken)
    {
        await using var db = await _dbContextFactory.CreateDbContextAsync(cancellationToken);

        var totalOrders = await db.Set<Order>().CountAsync(cancellationToken);
        var paidOrders = await db.Set<Order>().CountAsync(x => x.Status == OrderStatus.PaymentReceived, cancellationToken);
        var totalRevenue = await db.Set<Order>()
            .Where(x => x.Status == OrderStatus.PaymentReceived)
            .SumAsync(x => (decimal?)x.TotalAmount.amount, cancellationToken) ?? 0m;
        var revenueLast30Days = await db.Set<Order>()
            .Where(x => x.Status == OrderStatus.PaymentReceived && x.OrderDate >= cutoff)
            .SumAsync(x => (decimal?)x.TotalAmount.amount, cancellationToken) ?? 0m;
        var totalLibraryBooksGranted = await db.Set<UserBook>().CountAsync(cancellationToken);

        return (totalOrders, paidOrders, totalRevenue, revenueLast30Days, totalLibraryBooksGranted);
    }
}
