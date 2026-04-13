namespace LibroSphere.Domain.Entities.WishList
{
    public interface IWishlistRepository
    {
        Task<Wishlist?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
        Task<LibroSphere.Domain.Entities.ManyToMany.WishlistItem?> GetItemAsync(Guid wishlistId, Guid bookId, CancellationToken cancellationToken = default);
        void Add(Wishlist wishlist);
        void AddItem(LibroSphere.Domain.Entities.ManyToMany.WishlistItem item);
        void RemoveItem(LibroSphere.Domain.Entities.ManyToMany.WishlistItem item);
    }
}
