using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Books.Genre;
using LibroSphere.Domain.Entities.ManyToMany;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class BookRepository : RepositoryBase<Book>, IBookRepository
    {
        public BookRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<Book?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<Book>()
                .AsNoTracking()
                .AsSplitQuery()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);
        }

        public async Task<Book?> GetByIdWithDetailsForUpdateAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<Book>()
                .AsSplitQuery()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);
        }

        public async Task<List<Book>> GetByIdsWithDetailsAsync(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken = default)
        {
            if (ids.Count == 0)
            {
                return new List<Book>();
            }

            return await DbContext
                .Set<Book>()
                .AsNoTracking()
                .AsSplitQuery()
                .Where(b => ids.Contains(b.Id))
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .ToListAsync(cancellationToken);
        }

        public async Task<List<Book>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            var books = await DbContext
                .Set<Book>()
                .AsNoTracking()
                .AsSplitQuery()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .ToListAsync(cancellationToken);

            return books
                .OrderBy(b => b.Title)
                .ToList();
        }

        public async Task<List<Book>> SearchAsync(string? searchTerm, Guid? authorId, Guid? genreId, decimal? minPrice = null, decimal? maxPrice = null, double? minRating = null, CancellationToken cancellationToken = default)
        {
            var query = ApplySearchFilters(
                DbContext
                    .Set<Book>()
                    .AsNoTracking()
                    .AsSplitQuery()
                    .Include(b => b.Author)
                    .Include(b => b.BookGenres)
                        .ThenInclude(bg => bg.Genre),
                searchTerm,
                authorId,
                genreId,
                minPrice,
                maxPrice,
                minRating);

            return await query.OrderBy(b => b.Title).ToListAsync(cancellationToken);
        }

        public async Task<(List<Book> Items, int TotalCount)> SearchPagedAsync(
            string? searchTerm,
            Guid? authorId,
            Guid? genreId,
            decimal? minPrice,
            decimal? maxPrice,
            double? minRating,
            int page,
            int pageSize,
            CancellationToken cancellationToken = default)
        {
            var filteredQuery = ApplySearchFilters(
                DbContext.Set<Book>().AsNoTracking(),
                searchTerm,
                authorId,
                genreId,
                minPrice,
                maxPrice,
                minRating);

            var totalCount = await filteredQuery.CountAsync(cancellationToken);

            var items = await filteredQuery
                .OrderBy(b => b.Title)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .AsSplitQuery()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .ToListAsync(cancellationToken);

            return (items, totalCount);
        }

        private static IQueryable<Book> ApplySearchFilters(
            IQueryable<Book> query,
            string? searchTerm,
            Guid? authorId,
            Guid? genreId,
            decimal? minPrice,
            decimal? maxPrice,
            double? minRating)
        {
            var filtered = query;

            if (authorId.HasValue)
                filtered = filtered.Where(b => b.AuthorId == authorId.Value);

            if (genreId.HasValue)
                filtered = filtered.Where(b => b.BookGenres.Any(bg => bg.GenreId == genreId.Value));

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.Trim();
                filtered = filtered.Where(b =>
                    b.Title.Value.Contains(term) ||
                    b.Description.Value.Contains(term) ||
                    (b.Author != null && b.Author.Name.Value.Contains(term)));
            }

            if (minPrice.HasValue)
                filtered = filtered.Where(b => b.Price.amount >= minPrice.Value);

            if (maxPrice.HasValue)
                filtered = filtered.Where(b => b.Price.amount <= maxPrice.Value);

            if (minRating.HasValue)
                filtered = filtered.Where(b =>
                    b.Reviews.Count == 0
                        ? 0 >= minRating.Value
                        : b.Reviews.Average(r => (double)r.Rating) >= minRating.Value);

            return filtered;
        }

        public void ReplaceGenres(Book book, IReadOnlyCollection<Genre> genres)
        {
            var existingGenres = DbContext
                .Set<BookGenre>()
                .Where(bg => bg.BookId == book.Id)
                .ToList();

            if (existingGenres.Count > 0)
            {
                DbContext.Set<BookGenre>().RemoveRange(existingGenres);
            }

            book.BookGenres.Clear();

            foreach (var genre in genres)
            {
                var bookGenre = BookGenre.Create(book, genre);
                DbContext.Set<BookGenre>().Add(bookGenre);
                book.BookGenres.Add(bookGenre);
            }
        }

        public void Delete(Book book)
        {
            DbContext.Set<Book>().Remove(book);
        }
    }
}
