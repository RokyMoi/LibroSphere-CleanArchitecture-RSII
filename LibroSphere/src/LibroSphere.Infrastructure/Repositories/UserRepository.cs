using LibroSphere.Domain.Entities.Users;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class UserRepository : RepositoryBase<User>, IUserRepository
    {
        public UserRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
        {
            var normalizedEmail = email.Trim().ToLowerInvariant();
            return await DbContext
                .Set<User>()
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.UserEmail.Value == normalizedEmail, cancellationToken);
        }

        public async Task<User?> GetByIdWithFavoriteAuthorsAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<User>()
                .Include(u => u.FavoriteAuthors)
                .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
        }

        public async Task<List<User>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            var users = await DbContext
                .Set<User>()
                .AsNoTracking()
                .ToListAsync(cancellationToken);

            return users
                .OrderBy(u => u.FirstName.Value)
                .ThenBy(u => u.LastName.Value)
                .ToList();
        }

        public async Task<(List<User> Items, int TotalCount)> GetPagedAsync(
            string? searchTerm,
            bool? isActive,
            int page,
            int pageSize,
            CancellationToken cancellationToken = default)
        {
            var query = DbContext.Set<User>().AsNoTracking();

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.Trim().ToLowerInvariant();
                query = query.Where(u =>
                    EF.Property<string>(u, "FirstName").ToLower().Contains(term) ||
                    EF.Property<string>(u, "LastName").ToLower().Contains(term) ||
                    EF.Property<string>(u, "UserEmail").Contains(term));
            }

            if (isActive.HasValue)
                query = query.Where(u => u.IsActive == isActive.Value);

            var totalCount = await query.CountAsync(cancellationToken);

            var items = await query
                .OrderBy(u => EF.Property<string>(u, "FirstName"))
                .ThenBy(u => EF.Property<string>(u, "LastName"))
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            return (items, totalCount);
        }

        public void Delete(User user)
        {
            DbContext.Set<User>().Remove(user);
        }
    }
}
