namespace LibroSphere.Application.Events.Orders;

public sealed class OrderCreatedIntegrationEvent
{
    public OrderCreatedIntegrationEvent(Guid orderId, string buyerEmail, decimal totalAmount, string currency, int itemCount)
    {
        OrderId = orderId;
        BuyerEmail = buyerEmail;
        TotalAmount = totalAmount;
        Currency = currency;
        ItemCount = itemCount;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public OrderCreatedIntegrationEvent()
    {
        BuyerEmail = string.Empty;
        Currency = string.Empty;
    }

    public Guid OrderId { get; private set; }
    public string BuyerEmail { get; private set; }
    public decimal TotalAmount { get; private set; }
    public string Currency { get; private set; }
    public int ItemCount { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class OrderStatusChangedIntegrationEvent
{
    public OrderStatusChangedIntegrationEvent(Guid orderId, string buyerEmail, string status)
    {
        OrderId = orderId;
        BuyerEmail = buyerEmail;
        Status = status;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public OrderStatusChangedIntegrationEvent()
    {
        BuyerEmail = string.Empty;
        Status = string.Empty;
    }

    public Guid OrderId { get; private set; }
    public string BuyerEmail { get; private set; }
    public string Status { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
