using LibroSphere.Domain.Entities.Authors;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class AuthorRepository : RepositoryBase<Author>, IAuthorRepository
    {
        public AuthorRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<List<Author>> GetAllAsync(string? searchTerm = null, CancellationToken cancellationToken = default)
        {
            var query = DbContext
                .Set<Author>()
                .AsNoTracking()
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.Trim();
                query = query.Where(a =>
                    a.Name.Value.Contains(term) ||
                    a.Biography.Value.Contains(term));
            }

            return await query.OrderBy(a => a.Name.Value).ToListAsync(cancellationToken);
        }

        public void Delete(Author author)
        {
            DbContext.Set<Author>().Remove(author);
        }
    }
}
