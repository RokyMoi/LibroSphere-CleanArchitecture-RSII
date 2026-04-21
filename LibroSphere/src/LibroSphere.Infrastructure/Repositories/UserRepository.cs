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
            return await DbContext
                .Set<User>()
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.UserEmail.Value.ToLower() == email.ToLower(), cancellationToken);
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

        public void Delete(User user)
        {
            DbContext.Set<User>().Remove(user);
        }
    }
}
