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
            return await DbContext
                .Set<Author>()
                .OrderBy(a => a.Name.Value)
                .ToListAsync(cancellationToken);
        }

        public void Delete(Author author)
        {
            DbContext.Set<Author>().Remove(author);
        }
    }
}
