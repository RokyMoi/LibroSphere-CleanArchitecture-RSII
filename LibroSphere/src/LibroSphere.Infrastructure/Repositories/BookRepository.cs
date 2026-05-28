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
                .OrderBy(b => b.Title.Value)
                .ToList();
        }

        public async Task<List<Book>> SearchAsync(string? searchTerm, Guid? authorId, Guid? genreId, decimal? minPrice = null, decimal? maxPrice = null, double? minRating = null, CancellationToken cancellationToken = default)
        {
            var query = DbContext
                .Set<Book>()
                .AsNoTracking()
                .AsSplitQuery()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .AsQueryable();

            if (authorId.HasValue)
                query = query.Where(b => b.AuthorId == authorId.Value);

            if (genreId.HasValue)
                query = query.Where(b => b.BookGenres.Any(bg => bg.GenreId == genreId.Value));

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.Trim();
                query = query.Where(b =>
                    b.Title.Value.Contains(term) ||
                    b.Description.Value.Contains(term) ||
                    (b.Author != null && b.Author.Name.Value.Contains(term)));
            }

            if (minPrice.HasValue)
                query = query.Where(b => b.Price.amount >= minPrice.Value);

            if (maxPrice.HasValue)
                query = query.Where(b => b.Price.amount <= maxPrice.Value);

            if (minRating.HasValue)
                query = query.Where(b =>
                    b.Reviews.Count == 0
                        ? 0 >= minRating.Value
                        : b.Reviews.Average(r => (double)r.Rating) >= minRating.Value);

            return await query.OrderBy(b => b.Title.Value).ToListAsync(cancellationToken);
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
