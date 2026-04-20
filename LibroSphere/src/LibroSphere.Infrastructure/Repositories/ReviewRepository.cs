using LibroSphere.Domain.Entities.Reviews;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class ReviewRepository : RepositoryBase<Review>, IReviewRepository
    {
        public ReviewRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<List<Review>> GetByBookIdAsync(Guid bookId, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<Review>()
                .AsNoTracking()
                .Include(r => r.User)
                .Where(r => r.BookId == bookId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync(cancellationToken);
        }

        public async Task<List<Review>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<Review>()
                .AsNoTracking()
                .Include(r => r.Book)
                .Where(r => r.UserId == userId)
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

        public void Delete(Review review)
        {
            DbContext.Set<Review>().Remove(review);
        }
    }
}
