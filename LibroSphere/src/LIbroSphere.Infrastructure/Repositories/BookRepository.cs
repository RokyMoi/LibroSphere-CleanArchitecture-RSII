using LibroSphere.Domain.Entities.Books;
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
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .ToListAsync(cancellationToken);

            return books
                .OrderBy(b => b.Title.Value)
                .ToList();
        }

        public async Task<List<Book>> SearchAsync(string? searchTerm, Guid? authorId, Guid? genreId, CancellationToken cancellationToken = default)
        {
            var books = await DbContext
                .Set<Book>()
                .Include(b => b.Author)
                .Include(b => b.BookGenres)
                    .ThenInclude(bg => bg.Genre)
                .ToListAsync(cancellationToken);

            IEnumerable<Book> query = books;

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                query = query.Where(b =>
                    b.Title.Value.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) ||
                    b.Description.Value.Contains(searchTerm, StringComparison.OrdinalIgnoreCase) ||
                    b.Author.Name.Value.Contains(searchTerm, StringComparison.OrdinalIgnoreCase));
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

        public void Delete(Book book)
        {
            DbContext.Set<Book>().Remove(book);
        }
    }
}
