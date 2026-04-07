using LibroSphere.Application.Abstractions.Recommendations;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Reviews;
using LibroSphere.Domain.Entities.Users;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Services
{
    internal sealed class BookRecommendationService : IBookRecommendationService
    {
        private readonly ApplicationDbContext _dbContext;

        public BookRecommendationService(ApplicationDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<List<Book>> GetRecommendationsForUserAsync(Guid userId, int take = 5, CancellationToken cancellationToken = default)
        {
            var user = await _dbContext.Set<User>()
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

            if (user is null)
            {
                return new List<Book>();
            }

            var purchasedBookIds = await _dbContext.Set<LibroSphere.Domain.Entities.ManyToMany.UserBook>()
                .Where(ub => ub.UserEmail == user.UserEmail.Value)
                .Select(ub => ub.BookId)
                .ToListAsync(cancellationToken);

            var wishlistBookIds = await _dbContext.Set<LibroSphere.Domain.Entities.WishList.Wishlist>()
                .Where(w => w.UserId == userId)
                .SelectMany(w => w.Items.Select(i => i.BookId))
                .ToListAsync(cancellationToken);

            var reviewQuery = _dbContext.Set<Review>()
                .Where(r => r.UserId == userId);

            var favouriteGenreIds = await reviewQuery
                .Where(r => r.Rating >= 4)
                .Join(
                    _dbContext.Set<LibroSphere.Domain.Entities.ManyToMany.BookGenre>(),
                    review => review.BookId,
                    bookGenre => bookGenre.BookId,
                    (review, bookGenre) => bookGenre.GenreId)
                .GroupBy(id => id)
                .OrderByDescending(group => group.Count())
                .Select(group => group.Key)
                .Take(3)
                .ToListAsync(cancellationToken);

            IQueryable<Book> query = _dbContext.Set<Book>()
                .AsNoTracking()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .Include(b => b.Reviews)
                .Where(b => !purchasedBookIds.Contains(b.Id) && !wishlistBookIds.Contains(b.Id));

            if (favouriteGenreIds.Count > 0)
            {
                query = query.Where(b => b.BookGenres.Any(bg => favouriteGenreIds.Contains(bg.GenreId)));
            }

            var recommended = await query
                .OrderByDescending(b => b.Reviews.Any() ? b.Reviews.Average(r => r.Rating) : 0)
                .ThenBy(b => b.Title.Value)
                .Take(take)
                .ToListAsync(cancellationToken);

            if (recommended.Count == 0)
            {
                recommended = await _dbContext.Set<Book>()
                    .AsNoTracking()
                    .Include(b => b.Author)
                    .Include(b => b.BookGenres)
                        .ThenInclude(bg => bg.Genre)
                    .Include(b => b.Reviews)
                    .Where(b => !purchasedBookIds.Contains(b.Id))
                    .OrderByDescending(b => b.Reviews.Any() ? b.Reviews.Average(r => r.Rating) : 0)
                    .ThenBy(b => b.Title.Value)
                    .Take(take)
                    .ToListAsync(cancellationToken);
            }

            return recommended;
        }
    }
}
