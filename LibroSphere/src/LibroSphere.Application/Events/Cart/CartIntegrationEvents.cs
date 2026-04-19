namespace LibroSphere.Application.Events.Cart;

public sealed class CartUpdatedIntegrationEvent
{
    public CartUpdatedIntegrationEvent(Guid cartId, Guid userId, int itemCount, decimal totalAmount, string currency)
    {
        CartId = cartId;
        UserId = userId;
        ItemCount = itemCount;
        TotalAmount = totalAmount;
        Currency = currency;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public CartUpdatedIntegrationEvent()
    {
        Currency = string.Empty;
    }

    public Guid CartId { get; private set; }
    public Guid UserId { get; private set; }
    public int ItemCount { get; private set; }
    public decimal TotalAmount { get; private set; }
    public string Currency { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class CartDeletedIntegrationEvent
{
    public CartDeletedIntegrationEvent(Guid cartId)
    {
        CartId = cartId;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public CartDeletedIntegrationEvent()
    {
    }

    public Guid CartId { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
