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
                .FirstOrDefaultAsync(u => u.UserEmail.Value == email, cancellationToken);
        }

        public async Task<List<User>> GetAllAsync(CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<User>()
                .OrderBy(u => u.FirstName.Value)
                .ThenBy(u => u.LastName.Value)
                .ToListAsync(cancellationToken);
        }
    }
}
