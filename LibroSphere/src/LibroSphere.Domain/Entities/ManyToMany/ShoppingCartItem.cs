using System.Text.Json.Serialization;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.Shared;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Domain.Entities.ManyToMany
{
    public class ShoppingCartItem : BaseEntity
    {
        [JsonConstructor]
        public ShoppingCartItem(
            Guid id,
            Guid cartId,
            Guid bookId,
            Money price) : base(id)
        {
            CartId = cartId;
            BookId = bookId;
            Price = price;
        }

        protected ShoppingCartItem() { }

        public Guid CartId { get; private set; }
        public ShoppingCart Cart { get; private set; }
        public Guid BookId { get; private set; }
        public Book Book { get; private set; }
        public Money Price { get; private set; }

        public void SetPrice(Money price) => Price = price;

        public static ShoppingCartItem AddItem(Guid cartId, Guid bookId, Money price)
            => new ShoppingCartItem(Guid.NewGuid(), cartId, bookId, price);
    }
}
