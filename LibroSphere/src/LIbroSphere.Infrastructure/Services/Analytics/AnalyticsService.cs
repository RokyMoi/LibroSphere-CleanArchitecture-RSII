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
        var totalAuthors = await _dbContext.Set<Author>().CountAsync(cancellationToken);
        var totalBooks = await _dbContext.Set<Book>().CountAsync(cancellationToken);
        var totalGenres = await _dbContext.Set<Genre>().CountAsync(cancellationToken);
        var totalUsers = await _dbContext.Set<User>().CountAsync(cancellationToken);
        var activeUsers = await _dbContext.Set<User>().CountAsync(x => x.IsActive, cancellationToken);
        var totalReviews = await _dbContext.Set<Review>().CountAsync(cancellationToken);
        var totalWishlistItems = await _dbContext.Set<WishlistItem>().CountAsync(cancellationToken);
        var totalLibraryBooksGranted = await _dbContext.Set<UserBook>().CountAsync(cancellationToken);

        var books = await _dbContext.Set<Book>().AsNoTracking().ToListAsync(cancellationToken);
        var reviews = await _dbContext.Set<Review>().AsNoTracking().ToListAsync(cancellationToken);
        var orders = await _dbContext.Set<Order>().AsNoTracking().ToListAsync(cancellationToken);
        var users = await _dbContext.Set<User>().AsNoTracking().ToListAsync(cancellationToken);

        var averageBookPrice = books.Count == 0 ? 0m : books.Average(x => x.Price.amount);
        var averageReviewRating = reviews.Count == 0 ? 0d : reviews.Average(x => x.Rating);
        var paidOrders = orders.Count(x => x.Status == OrderStatus.PaymentReceived);
        var totalRevenue = orders
            .Where(x => x.Status == OrderStatus.PaymentReceived)
            .Select(x => x.TotalAmount.amount)
            .DefaultIfEmpty(0m)
            .Sum();

        var cutoff = DateTime.UtcNow.AddDays(-30);
        var revenueLast30Days = orders
            .Where(x => x.Status == OrderStatus.PaymentReceived && x.OrderDate >= cutoff)
            .Select(x => x.TotalAmount.amount)
            .DefaultIfEmpty(0m)
            .Sum();

        var usersWithLast30DayLogin = users.Count(x => x.LastLogin.HasValue && x.LastLogin.Value >= cutoff);
        var recentActivity = await _activityStore.GetRecentAsync(recentActivityTake, cancellationToken);

        return new AnalyticsOverviewResponse
        {
            Catalog = CatalogAnalyticsCalculation.Calculate(totalAuthors, totalBooks, totalGenres, averageBookPrice, averageReviewRating),
            Commerce = CommerceAnalyticsCalculation.Calculate(orders.Count, paidOrders, totalRevenue, revenueLast30Days, totalLibraryBooksGranted),
            Engagement = EngagementAnalyticsCalculation.Calculate(totalUsers, activeUsers, totalReviews, totalWishlistItems, usersWithLast30DayLogin),
            RecentActivity = recentActivity
        };
    }
}
