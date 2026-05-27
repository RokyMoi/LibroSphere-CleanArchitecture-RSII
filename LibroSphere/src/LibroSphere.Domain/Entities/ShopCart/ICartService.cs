using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Domain.Entities.ShopCart
{
    public interface ICartService
    {
        Task<ShoppingCart?> GetCartAsync(string key, CancellationToken cancellationToken = default);
        Task<ShoppingCart?> SetCartAsync(ShoppingCart cart, CancellationToken cancellationToken = default);
        Task<bool> DeleteCartAsync(string key, CancellationToken cancellationToken = default);
    }
}