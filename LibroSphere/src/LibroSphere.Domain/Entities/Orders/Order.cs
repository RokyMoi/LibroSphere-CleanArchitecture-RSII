using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Orders.Events;
using LibroSphere.Domain.Entities.Shared;

namespace LibroSphere.Domain.Entities.Orders
{
    public class Order : BaseEntity
    {
        private Order(
            Guid id,
            string buyerEmail,
            List<OrderItem> items,
            string paymentIntentId,
            Money totalAmount,
            string clientSecret)
            : base(id)
        {
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

        public string BuyerEmail { get; private set; }
        public DateTime OrderDate { get; private set; }
        public List<OrderItem> Items { get; private set; } = new();
        public Money TotalAmount { get; private set; }
        public OrderStatus Status { get; private set; }
        public string PaymentIntentId { get; private set; }
        public string? ClientSecret { get; private set; }

        public static Order Create(
            string buyerEmail,
            List<OrderItem> items,
            string paymentIntentId,
            string clientSecret)
        {
            var total = items.Count == 0
                ? Money.Zero()
                : items
                    .Select(item => new Money(item.Price.amount * item.Quantity, item.Price.Currency))
                    .Aggregate((sum, item) => sum + item);

            var order = new Order(Guid.NewGuid(), buyerEmail, items, paymentIntentId, total, clientSecret);
            order.RaiseDomainEvent(
                new OrderCreatedDomainEvent(
                    order.Id,
                    order.BuyerEmail,
                    order.TotalAmount.amount,
                    order.TotalAmount.Currency.Code,
                    order.Items.Count));

            return order;
        }

        public void UpdateStatus(OrderStatus status)
        {
            if (Status == status)
            {
                return;
            }

            Status = status;
            RaiseDomainEvent(new OrderStatusChangedDomainEvent(Id, BuyerEmail, Status.ToString()));
        }
    }
}
