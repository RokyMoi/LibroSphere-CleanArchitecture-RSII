using LibroSphere.Domain.Entities.Authors;
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
            var query = ApplyStructuredFilters(
                DbContext
                    .Set<Book>()
                    .AsNoTracking()
                    .AsSplitQuery()
                    .Include(b => b.Author)
                    .Include(b => b.BookGenres)
                        .ThenInclude(bg => bg.Genre),
                authorId,
                genreId,
                minPrice,
                maxPrice,
                minRating);

            var books = await query.ToListAsync(cancellationToken);

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.Trim();
                books = books.Where(b => MatchesSearchTerm(b, term)).ToList();
            }

            return books.OrderBy(b => b.Title.Value).ToList();
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
            var filteredQuery = ApplyStructuredFilters(
                DbContext.Set<Book>().AsNoTracking(),
                authorId,
                genreId,
                minPrice,
                maxPrice,
                minRating);

            // No text term: keep efficient DB-side pagination.
            if (string.IsNullOrWhiteSpace(searchTerm))
            {
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

            // Text term present: value-converted columns can't be filtered in SQL, so materialize
            // the structurally-filtered set (with author/genres) and match + paginate in memory.
            var term = searchTerm.Trim();

            var candidates = await filteredQuery
                .AsSplitQuery()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .ToListAsync(cancellationToken);

            var matched = candidates
                .Where(b => MatchesSearchTerm(b, term))
                .OrderBy(b => b.Title.Value)
                .ToList();

            var pageItems = matched
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            return (pageItems, matched.Count);
        }

        // Note: searchTerm is intentionally NOT handled here. Title/Description/Author.Name are
        // value objects mapped through EF value converters, and EF Core cannot translate string
        // operations (LIKE/Contains) over converted columns. The text match is therefore applied
        // in memory by the callers (see MatchesSearchTerm) only when a term is supplied.
        private static IQueryable<Book> ApplyStructuredFilters(
            IQueryable<Book> query,
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

        private static bool MatchesSearchTerm(Book book, string term) =>
            book.Title.Value.Contains(term, StringComparison.OrdinalIgnoreCase) ||
            book.Description.Value.Contains(term, StringComparison.OrdinalIgnoreCase) ||
            (book.Author is not null &&
             book.Author.Name.Value.Contains(term, StringComparison.OrdinalIgnoreCase));

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
