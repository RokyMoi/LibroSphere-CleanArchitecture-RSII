using LibroSphere.Application.Events.Cart;
using LibroSphere.Domain.Entities.ShopCart;
using MassTransit;
using StackExchange.Redis;
using System.Text.Json;

namespace LibroSphere.Infrastructure.Services
{
    public class CartService : ICartService
    {
        private readonly IDatabase _database;
        private readonly IPublishEndpoint _publishEndpoint;

        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true,
            IncludeFields = true
        };

        public CartService(IConnectionMultiplexer redis, IPublishEndpoint publishEndpoint)
        {
            _database = redis.GetDatabase();
            _publishEndpoint = publishEndpoint;
        }

        public async Task<bool> DeleteCartAsync(string key)
        {
            var deleted = await _database.KeyDeleteAsync(key);
            if (deleted && Guid.TryParse(key, out var cartId))
            {
                await _publishEndpoint.Publish(new CartDeletedIntegrationEvent(cartId));
            }

            return deleted;
        }

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
                TimeSpan.FromDays(30));

            if (!created)
            {
                return null;
            }

            var total = cart.GetTotal();
            await _publishEndpoint.Publish(
                new CartUpdatedIntegrationEvent(
                    cart.Id,
                    cart.UserId,
                    cart.Items.Count,
                    total.amount,
                    total.Currency.Code));

            return await GetCartASync(cart.Id.ToString());
        }
    }
}
