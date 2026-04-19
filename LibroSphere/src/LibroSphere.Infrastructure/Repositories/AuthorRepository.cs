using LibroSphere.Domain.Entities.Authors;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class AuthorRepository : RepositoryBase<Author>, IAuthorRepository
    {
        public AuthorRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<List<Author>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            var authors = await DbContext
                .Set<Author>()
                .ToListAsync(cancellationToken);

            return authors
                .OrderBy(a => a.Name.Value)
                .ToList();
        }

        public void Delete(Author author)
        {
            DbContext.Set<Author>().Remove(author);
        }
    }
}
