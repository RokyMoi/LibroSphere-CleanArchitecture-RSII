using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Domain.Entities.ShopCart
{
    public interface ICartService
    {
        Task<ShoppingCart?> GetCartASync(string key);
        Task<ShoppingCart?> SetCartAsync(ShoppingCart cart);
        Task<bool> DeleteCartAsync(string key);
    }
}