using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Orders.Events;
using LibroSphere.Domain.Entities.Shared;
using LibroSphere.Domain.Entities.Users;

namespace LibroSphere.Domain.Entities.Orders
{
    public class Order : BaseEntity
    {
        private Order(
            Guid id,
            Guid userId,
            string buyerEmail,
            List<OrderItem> items,
            string paymentIntentId,
            Money totalAmount,
            string clientSecret)
            : base(id)
        {
            UserId = userId;
            BuyerEmail = buyerEmail;
            Items = items;
            PaymentIntentId = paymentIntentId;
            TotalAmount = totalAmount;
            ClientSecret = clientSecret;
            Status = OrderStatus.Pending;
            OrderDate = DateTime.UtcNow;
        }

        protected Order()
        {
        }

        public Guid UserId { get; private set; }
        public User User { get; private set; } = null!;
        public string BuyerEmail { get; private set; } = string.Empty;
        public DateTime OrderDate { get; private set; }
        public List<OrderItem> Items { get; private set; } = new();
        public Money TotalAmount { get; private set; } = null!;
        public OrderStatus Status { get; private set; }
        public string PaymentIntentId { get; private set; } = string.Empty;
        public string? ClientSecret { get; private set; }

        public static Order Create(
            Guid userId,
            string buyerEmail,
            List<OrderItem> items,
            string paymentIntentId,
            string clientSecret)
        {
            if (items.Count == 0)
            {
                throw new InvalidOperationException("Order must contain at least one item.");
            }

            var total = items
                .Select(item => new Money(item.Price.amount * item.Quantity, item.Price.Currency))
                .Aggregate((sum, item) => sum + item);

            var order = new Order(Guid.NewGuid(), userId, buyerEmail, items, paymentIntentId, total, clientSecret);
            order.RaiseDomainEvent(
                new OrderCreatedDomainEvent(
                    order.Id,
                    order.BuyerEmail,
                    order.TotalAmount.amount,
                    order.TotalAmount.Currency.Code,
                    order.Items.Count));

            return order;
        }

        public void UpdateStatus(OrderStatus newStatus)
        {
            if (Status == newStatus)
            {
                return;
            }

            bool isValidTransition = (Status, newStatus) switch
            {
                (OrderStatus.Pending, OrderStatus.PaymentReceived) => true,
                (OrderStatus.Pending, OrderStatus.PaymentFailed) => true,
                (OrderStatus.PaymentReceived, OrderStatus.Refunded) => true,
                (OrderStatus.PaymentReceived, OrderStatus.PartiallyRefunded) => true,
                _ => false
            };

            if (!isValidTransition)
            {
                throw new InvalidOperationException($"Invalid state transition from {Status} to {newStatus}");
            }

            Status = newStatus;
            RaiseDomainEvent(new OrderStatusChangedDomainEvent(Id, BuyerEmail, Status.ToString()));
        }
    }
}
