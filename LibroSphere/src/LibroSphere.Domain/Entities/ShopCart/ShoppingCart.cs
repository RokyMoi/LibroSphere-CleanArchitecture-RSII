using System.Text.Json.Serialization;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Shared;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Domain.Entities.ShopCart
{
    public class ShoppingCart : BaseEntity
    {
        private ShoppingCart(Guid id, Guid userId) : base(id)
        {
            UserId = userId;
            Items = new List<ShoppingCartItem>();
        }

        [JsonConstructor]
        public ShoppingCart(
            Guid id,
            Guid userId,
            string? clientSecret,
            string? paymentIntentId,
            List<ShoppingCartItem>? items) : base(id)
        {
            UserId = userId;
            ClientSecret = clientSecret;
            PaymentIntentId = paymentIntentId;
            Items = items ?? new List<ShoppingCartItem>();
        }

        protected ShoppingCart() { }

        public Guid UserId { get; private set; }
        public User User { get; private set; } = null!;
        public string? ClientSecret { get; set; }
        public string? PaymentIntentId { get; private set; }
        public List<ShoppingCartItem> Items { get; private set; } = new();

        public void SetPaymentIntent(string paymentIntentId)
        {
            PaymentIntentId = paymentIntentId;
        }

        public static ShoppingCart CreateCart(Guid userId)
            => new ShoppingCart(Guid.NewGuid(), userId);

        public static ShoppingCart CreateCart(Guid id, Guid userId)
            => new ShoppingCart(id, userId);

        public Money GetTotal() => Items.Count == 0
            ? Money.Zero()
            : Items
                .Select(item => new Money(item.Price.amount, item.Price.Currency))
                .Aggregate((sum, item) => sum + item);
    }
}
