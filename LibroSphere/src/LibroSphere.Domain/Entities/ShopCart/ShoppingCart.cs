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

        protected ShoppingCart() { }

        public Guid UserId { get; private set; }
        public User User { get; private set; }

  
        public string? ClientSecret { get; set; }
        public string? PaymentIntentId { get; private set; }

        public void SetPaymentIntent(string paymentIntentId)
        {
            PaymentIntentId = paymentIntentId;
        }

       
        public List<ShoppingCartItem> Items { get; private set; } = new();

        public static ShoppingCart CreateCart(Guid userId)
            => new ShoppingCart(Guid.NewGuid(), userId);

        public Money GetTotal() => Items.Aggregate(
            Money.Zero(),
            (sum, item) => sum + new Money(item.Price.amount, item.Price.Currency)
        );
    }
}