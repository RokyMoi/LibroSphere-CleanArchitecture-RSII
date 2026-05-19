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
    private readonly ApplicationDbContext _dbContext;
    private readonly IAnalyticsActivityStore _activityStore;

    public AnalyticsService(ApplicationDbContext dbContext, IAnalyticsActivityStore activityStore)
    {
        _dbContext = dbContext;
        _activityStore = activityStore;
    }

    public async Task<AnalyticsOverviewResponse> GetOverviewAsync(int recentActivityTake, CancellationToken cancellationToken = default)
    {
        var cutoff = DateTime.UtcNow.AddDays(-30);

        var totalAuthors = await _dbContext.Set<Author>().CountAsync(cancellationToken);
        var totalBooks = await _dbContext.Set<Book>().CountAsync(cancellationToken);
        var totalGenres = await _dbContext.Set<Genre>().CountAsync(cancellationToken);
        var totalUsers = await _dbContext.Set<User>().CountAsync(cancellationToken);
        var activeUsers = await _dbContext.Set<User>().CountAsync(x => x.IsActive, cancellationToken);
        var totalReviews = await _dbContext.Set<Review>().CountAsync(cancellationToken);
        var totalWishlistItems = await _dbContext.Set<WishlistItem>().CountAsync(cancellationToken);
        var totalLibraryBooksGranted = await _dbContext.Set<UserBook>().CountAsync(cancellationToken);

        var averageBookPrice = await _dbContext.Set<Book>()
            .AverageAsync(x => (decimal?)x.Price.amount, cancellationToken) ?? 0m;

        var averageReviewRating = await _dbContext.Set<Review>()
            .AverageAsync(x => (double?)x.Rating, cancellationToken) ?? 0d;

        var totalOrders = await _dbContext.Set<Order>().CountAsync(cancellationToken);

        var paidOrders = await _dbContext.Set<Order>()
            .CountAsync(x => x.Status == OrderStatus.PaymentReceived, cancellationToken);

        var totalRevenue = await _dbContext.Set<Order>()
            .Where(x => x.Status == OrderStatus.PaymentReceived)
            .SumAsync(x => (decimal?)x.TotalAmount.amount, cancellationToken) ?? 0m;

        var revenueLast30Days = await _dbContext.Set<Order>()
            .Where(x => x.Status == OrderStatus.PaymentReceived && x.OrderDate >= cutoff)
            .SumAsync(x => (decimal?)x.TotalAmount.amount, cancellationToken) ?? 0m;

        var usersWithLast30DayLogin = await _dbContext.Set<User>()
            .CountAsync(x => x.LastLogin.HasValue && x.LastLogin.Value >= cutoff, cancellationToken);

        var recentActivity = await _activityStore.GetRecentAsync(recentActivityTake, cancellationToken);

        return new AnalyticsOverviewResponse
        {
            Catalog = CatalogAnalyticsCalculation.Calculate(totalAuthors, totalBooks, totalGenres, averageBookPrice, averageReviewRating),
            Commerce = CommerceAnalyticsCalculation.Calculate(totalOrders, paidOrders, totalRevenue, revenueLast30Days, totalLibraryBooksGranted),
            Engagement = EngagementAnalyticsCalculation.Calculate(totalUsers, activeUsers, totalReviews, totalWishlistItems, usersWithLast30DayLogin),
            RecentActivity = recentActivity
        };
    }
}
