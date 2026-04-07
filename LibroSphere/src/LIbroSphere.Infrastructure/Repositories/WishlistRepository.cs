using LibroSphere.Domain.Entities.WishList;
using Microsoft.EntityFrameworkCore;

namespace LibroSphere.Infrastructure.Repositories
{
    internal sealed class WishlistRepository : RepositoryBase<Wishlist>, IWishlistRepository
    {
        public WishlistRepository(ApplicationDbContext dbContext) : base(dbContext)
        {
        }

        public async Task<Wishlist?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<Wishlist>()
                .Include(w => w.Items)
                    .ThenInclude(i => i.Book)
                .FirstOrDefaultAsync(w => w.UserId == userId, cancellationToken);
        }
    }
}
