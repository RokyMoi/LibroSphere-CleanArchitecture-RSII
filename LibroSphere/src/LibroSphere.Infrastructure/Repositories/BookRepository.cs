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
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .Include(b => b.Reviews)
                .FirstOrDefaultAsync(b => b.Id == id, cancellationToken);
        }

        public async Task<List<Book>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            var books = await DbContext
                .Set<Book>()
                .AsNoTracking()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .Include(b => b.Reviews)
                .ToListAsync(cancellationToken);

            return books
                .OrderBy(b => b.Title.Value)
                .ToList();
        }

        public async Task<List<Book>> SearchAsync(string? searchTerm, Guid? authorId, Guid? genreId, CancellationToken cancellationToken = default)
        {
            var books = await DbContext
                .Set<Book>()
                .AsNoTracking()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .Include(b => b.Reviews)
                .ToListAsync(cancellationToken);

            IEnumerable<Book> query = books;

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var normalizedSearchTerm = searchTerm.Trim();
                query = query.Where(b =>
                    b.Title.Value.Contains(normalizedSearchTerm, StringComparison.OrdinalIgnoreCase) ||
                    b.Description.Value.Contains(normalizedSearchTerm, StringComparison.OrdinalIgnoreCase) ||
                    b.Author.Name.Value.Contains(normalizedSearchTerm, StringComparison.OrdinalIgnoreCase));
            }

            if (authorId.HasValue)
            {
                query = query.Where(b => b.AuthorId == authorId.Value);
            }

            if (genreId.HasValue)
            {
                query = query.Where(b => b.BookGenres.Any(bg => bg.GenreId == genreId.Value));
            }

            return query
                .OrderBy(b => b.Title.Value)
                .ToList();
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
