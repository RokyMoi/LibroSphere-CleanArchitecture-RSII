using LibroSphere.Domain.Entities.Books.Genre;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class GenreRepository : RepositoryBase<Genre>, IGenreRepository
    {
        public GenreRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<Genre?> GetByNameAsync(string name, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<Genre>()
                .FirstOrDefaultAsync(g => g.Name.Value == name, cancellationToken);
        }

        public async Task<List<Genre>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<Genre>()
                .OrderBy(g => g.Name.Value)
                .ToListAsync(cancellationToken);
        }

        public async Task<List<Genre>> GetByIdsAsync(IEnumerable<Guid> ids, CancellationToken cancellationToken = default)
        {
            var idList = ids.Distinct().ToList();
            return await DbContext
                .Set<Genre>()
                .Where(g => idList.Contains(g.Id))
                .ToListAsync(cancellationToken);
        }
    }
}
