using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Shared;

namespace LibroSphere.Domain.Entities.Orders
{
    public class OrderItem : BaseEntity
    {
        private OrderItem(
            Guid id,
            Guid bookId,
            string title,
            string? imageLink,
            Money price,
            int quantity) : base(id)
        {
            BookId = bookId;
            Title = title;
            ImageLink = imageLink;
            Price = price;
            Quantity = quantity;
        }

        protected OrderItem() { }

        public Guid BookId { get; private set; }
        public string Title { get; private set; } = string.Empty;
        public string? ImageLink { get; private set; }
        public Money Price { get; private set; } = null!;
        public int Quantity { get; private set; }

        public static OrderItem Create(
            Guid bookId,
            string title,
            string? imageLink,
            Money price,
            int quantity = 1)   // default 1 - one copy pdf :)
            => new(Guid.NewGuid(), bookId, title, imageLink, price, quantity);
    }
}
