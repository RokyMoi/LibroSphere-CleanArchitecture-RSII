using LibroSphere.Domain.Entities.ShopCart;
using StackExchange.Redis;
using System.Text.Json;

namespace LibroSphere.Infrastructure.Services
{
    public class CartService : ICartService
    {
        private readonly IDatabase _database;

        // opcije koje omogucavaju private setere
        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true,
            IncludeFields = true
        };

        public CartService(IConnectionMultiplexer redis)
        {
            _database = redis.GetDatabase();
        }

        public async Task<bool> DeleteCartAsync(string key)
            => await _database.KeyDeleteAsync(key);

        public async Task<ShoppingCart?> GetCartASync(string key)
        {
            var data = await _database.StringGetAsync(key);
            return data.IsNullOrEmpty
                ? null
                : JsonSerializer.Deserialize<ShoppingCart>(data!, _jsonOptions);
        }

        public async Task<ShoppingCart?> SetCartAsync(ShoppingCart cart)
        {
            var json = JsonSerializer.Serialize(cart, _jsonOptions);
            var created = await _database.StringSetAsync(
                cart.Id.ToString(),
                json,
                TimeSpan.FromDays(30)
            );
            if (!created) return null;
            return await GetCartASync(cart.Id.ToString());
        }
    }
}