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

    public Guid OrderId { get; init; }
    public string BuyerEmail { get; init; }
    public decimal TotalAmount { get; init; }
    public string Currency { get; init; }
    public int ItemCount { get; init; }
    public DateTime OccurredOnUtc { get; init; }
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

    public Guid OrderId { get; init; }
    public string BuyerEmail { get; init; }
    public string Status { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}
