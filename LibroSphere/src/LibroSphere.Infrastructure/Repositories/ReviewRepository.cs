using LibroSphere.Domain.Entities.Reviews;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class ReviewRepository : RepositoryBase<Review>, IReviewRepository
    {
        public ReviewRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<List<Review>> GetByBookIdAsync(Guid bookId, int? minRating = null, int? maxRating = null, CancellationToken cancellationToken = default)
        {
            var query = ApplyRatingFilters(
                DbContext
                    .Set<Review>()
                    .AsNoTracking()
                    .Include(r => r.User)
                    .Where(r => r.BookId == bookId),
                minRating,
                maxRating);

            return await query
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);
        }

        public async Task<List<Review>> GetByUserIdAsync(Guid userId, int? minRating = null, int? maxRating = null, CancellationToken cancellationToken = default)
        {
            var query = ApplyRatingFilters(
                DbContext
                    .Set<Review>()
                    .AsNoTracking()
                    .Include(r => r.Book)
                    .Where(r => r.UserId == userId),
                minRating,
                maxRating);

            return await query
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);
        }

        public async Task<(List<Review> Items, int TotalCount)> GetPagedByBookIdAsync(
            Guid bookId,
            int? minRating,
            int? maxRating,
            int page,
            int pageSize,
            CancellationToken cancellationToken = default)
        {
            var query = ApplyRatingFilters(
                DbContext
                    .Set<Review>()
                    .AsNoTracking()
                    .Include(r => r.User)
                    .Where(r => r.BookId == bookId),
                minRating,
                maxRating);

            var totalCount = await query.CountAsync(cancellationToken);
            var items = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            return (items, totalCount);
        }

        public async Task<(List<Review> Items, int TotalCount)> GetPagedByUserIdAsync(
            Guid userId,
            int? minRating,
            int? maxRating,
            int page,
            int pageSize,
            CancellationToken cancellationToken = default)
        {
            var query = ApplyRatingFilters(
                DbContext
                    .Set<Review>()
                    .AsNoTracking()
                    .Include(r => r.Book)
                    .Where(r => r.UserId == userId),
                minRating,
                maxRating);

            var totalCount = await query.CountAsync(cancellationToken);
            var items = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            return (items, totalCount);
        }

        private static IQueryable<Review> ApplyRatingFilters(
            IQueryable<Review> query,
            int? minRating,
            int? maxRating)
        {
            if (minRating.HasValue)
                query = query.Where(r => r.Rating >= minRating.Value);

            if (maxRating.HasValue)
                query = query.Where(r => r.Rating <= maxRating.Value);

            return query;
        }

        public async Task<Review?> GetByUserAndBookAsync(Guid userId, Guid bookId, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<Review>()
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.UserId == userId && r.BookId == bookId, cancellationToken);
        }

        public async Task<IReadOnlyDictionary<Guid, BookReviewStats>> GetStatsForBooksAsync(IReadOnlyCollection<Guid> bookIds, CancellationToken cancellationToken = default)
        {
            if (bookIds.Count == 0)
            {
                return new Dictionary<Guid, BookReviewStats>();
            }

            var stats = await DbContext
                .Set<Review>()
                .AsNoTracking()
                .Where(r => bookIds.Contains(r.BookId))
                .GroupBy(r => r.BookId)
                .Select(g => new { BookId = g.Key, Count = g.Count(), Average = g.Average(r => (double)r.Rating) })
                .ToListAsync(cancellationToken);

            return stats.ToDictionary(s => s.BookId, s => new BookReviewStats(s.Count, s.Average));
        }

        public void Delete(Review review)
        {
            DbContext.Set<Review>().Remove(review);
        }
    }
}
