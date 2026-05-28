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
            var query = DbContext
                .Set<Review>()
                .AsNoTracking()
                .Include(r => r.User)
                .Where(r => r.BookId == bookId);

            if (minRating.HasValue)
                query = query.Where(r => r.Rating >= minRating.Value);

            if (maxRating.HasValue)
                query = query.Where(r => r.Rating <= maxRating.Value);

            return await query
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);
        }

        public async Task<List<Review>> GetByUserIdAsync(Guid userId, int? minRating = null, int? maxRating = null, CancellationToken cancellationToken = default)
        {
            var query = DbContext
                .Set<Review>()
                .AsNoTracking()
                .Include(r => r.Book)
                .Where(r => r.UserId == userId);

            if (minRating.HasValue)
                query = query.Where(r => r.Rating >= minRating.Value);

            if (maxRating.HasValue)
                query = query.Where(r => r.Rating <= maxRating.Value);

            return await query
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);
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
