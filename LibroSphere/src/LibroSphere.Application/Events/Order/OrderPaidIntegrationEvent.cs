namespace LibroSphere.Application.Events.Order
{
    public sealed class OrderPaidIntegrationEvent
    {
        public OrderPaidIntegrationEvent()
        {
            BuyerEmail = string.Empty;
            Currency = string.Empty;
            Items = Array.Empty<OrderPaidItem>();
        }

        public OrderPaidIntegrationEvent(
            Guid orderId,
            string buyerEmail,
            decimal totalAmount,
            string currency,
            IReadOnlyCollection<OrderPaidItem> items)
        {
            OrderId = orderId;
            BuyerEmail = buyerEmail;
            TotalAmount = totalAmount;
            Currency = currency;
            Items = items;
        }

        public Guid OrderId { get; private set; }
        public string BuyerEmail { get; private set; }
        public decimal TotalAmount { get; private set; }
        public string Currency { get; private set; }
        public IReadOnlyCollection<OrderPaidItem> Items { get; private set; }
    }

    public sealed class OrderPaidItem
    {
        public OrderPaidItem()
        {
            Title = string.Empty;
            Currency = string.Empty;
        }

        public OrderPaidItem(string title, decimal amount, string currency, int quantity)
        {
            Title = title;
            Amount = amount;
            Currency = currency;
            Quantity = quantity;
        }

        public string Title { get; private set; }
        public decimal Amount { get; private set; }
        public string Currency { get; private set; }
        public int Quantity { get; private set; }
    }
}
