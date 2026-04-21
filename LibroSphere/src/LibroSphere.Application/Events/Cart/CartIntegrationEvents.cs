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

    public Guid CartId { get; init; }
    public Guid UserId { get; init; }
    public int ItemCount { get; init; }
    public decimal TotalAmount { get; init; }
    public string Currency { get; init; }
    public DateTime OccurredOnUtc { get; init; }
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

    public Guid CartId { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}
