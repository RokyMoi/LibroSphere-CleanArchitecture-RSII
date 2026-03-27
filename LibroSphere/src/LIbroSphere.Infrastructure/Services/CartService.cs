using LibroSphere.Domain.Entities.ShopCart;
using StackExchange.Redis;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace LibroSphere.Infrastructure.Services
{
    public class CartService(IConnectionMultiplexer redis) : ICartService
    {
        private readonly IDatabase _database = redis.GetDatabase();
        public async Task<bool> DeleteCartAsync(string key)
        {
            return await _database.KeyDeleteAsync(key);
        }

        public async Task<ShoppingCart?> GetCartASync(string key)
        {
            var data = await _database.StringGetAsync(key);
            return  data.IsNullOrEmpty ? null : JsonSerializer.Deserialize<ShoppingCart?>(data);
        }

        public async Task<ShoppingCart?> SetCartAsync(ShoppingCart cart)
        {
            var created = await _database.
                StringSetAsync(cart.Id.ToString(), JsonSerializer.Serialize(cart), TimeSpan.FromDays(30));
            if (!created) return null;
            return await GetCartASync(cart.Id.ToString());   
        }
    }
}
