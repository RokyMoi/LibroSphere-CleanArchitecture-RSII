using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Orders.Events;

public sealed class OrderCreatedDomainEvent(Guid orderId, string buyerEmail, decimal totalAmount, string currency, int itemCount) : IDomainEvent
{
    public Guid OrderId { get; } = orderId;
    public string BuyerEmail { get; } = buyerEmail;
    public decimal TotalAmount { get; } = totalAmount;
    public string Currency { get; } = currency;
    public int ItemCount { get; } = itemCount;
}
