using LibroSphere.Domain.Entities.WishList;
using LibroSphere.Domain.Entities.ManyToMany;
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

        public async Task<WishlistItem?> GetItemAsync(Guid wishlistId, Guid bookId, CancellationToken cancellationToken = default)
        {
            return await DbContext
                .Set<WishlistItem>()
                .FirstOrDefaultAsync(i => i.WishlistId == wishlistId && i.BookId == bookId, cancellationToken);
        }

        public void AddItem(WishlistItem item)
        {
            DbContext.Set<WishlistItem>().Add(item);
        }

        public void RemoveItem(WishlistItem item)
        {
            DbContext.Set<WishlistItem>().Remove(item);
        }
    }
}
