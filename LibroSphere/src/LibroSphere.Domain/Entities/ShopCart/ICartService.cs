using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Domain.Entities.ShopCart
{
    public interface ICartService
    {
        Task<ShoppingCart?> GetCartASync(string key);
        Task<ShoppingCart?> SetCartAsync (ShoppingCart cart);
        Task<bool> DeleteCartAsync(string key);
    }
}
