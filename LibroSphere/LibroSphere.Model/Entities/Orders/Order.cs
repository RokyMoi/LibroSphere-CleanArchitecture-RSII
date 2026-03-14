using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.Shared;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Domain.Entities.Orders
{
    public class Order : BaseEntity
    {
        private Order(
            Guid id,
            Guid userId,
            Money totalPrice,
            PaymentStatuses paymentStatus,
            DateTime createdAt) : base(id)
        {
            UserId = userId;
            TotalPrice = totalPrice;
            PaymentStatus = paymentStatus;
            CreatedAt = createdAt;

            Items = new List<OrderItem>();
        }

        public Guid UserId { get; private set; }
        public User User { get; private set; }

        public Money TotalPrice { get; private set; }

        public PaymentStatuses PaymentStatus { get; private set; }

        public DateTime CreatedAt { get; private set; }

        public ICollection<OrderItem> Items { get; private set; }

        public static Order CreateOrder(
            Guid userId,
            Money totalPrice,
            PaymentStatuses paymentStatus)
        {
            var newOrder = new Order(
                Guid.NewGuid(),
                userId,
                totalPrice,
                paymentStatus,
                DateTime.UtcNow
            );

            return newOrder;
        }
    }
}