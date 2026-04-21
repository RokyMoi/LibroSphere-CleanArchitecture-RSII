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

        public Guid OrderId { get; init; }
        public string BuyerEmail { get; init; }
        public decimal TotalAmount { get; init; }
        public string Currency { get; init; }
        public IReadOnlyCollection<OrderPaidItem> Items { get; init; }
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

        public string Title { get; init; }
        public decimal Amount { get; init; }
        public string Currency { get; init; }
        public int Quantity { get; init; }
    }
}
