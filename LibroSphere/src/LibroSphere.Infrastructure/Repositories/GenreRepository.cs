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
            var genres = await DbContext
                .Set<Genre>()
                .ToListAsync(cancellationToken);

            return genres.FirstOrDefault(g => g.Name.Value.Equals(name, StringComparison.OrdinalIgnoreCase));
        }

        public async Task<List<Genre>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            var genres = await DbContext
                .Set<Genre>()
                .ToListAsync(cancellationToken);

            return genres
                .OrderBy(g => g.Name.Value)
                .ToList();
        }

        public async Task<List<Genre>> GetByIdsAsync(IEnumerable<Guid> ids, CancellationToken cancellationToken = default)
        {
            var idList = ids.Distinct().ToList();
            return await DbContext
                .Set<Genre>()
                .Where(g => idList.Contains(g.Id))
                .ToListAsync(cancellationToken);
        }

        public void Delete(Genre genre)
        {
            DbContext.Set<Genre>().Remove(genre);
        }
    }
}
