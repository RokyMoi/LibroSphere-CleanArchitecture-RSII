using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Orders.Events;

public sealed class OrderStatusChangedDomainEvent(Guid orderId, string buyerEmail, string status) : IDomainEvent
{
    public Guid OrderId { get; } = orderId;
    public string BuyerEmail { get; } = buyerEmail;
    public string Status { get; } = status;
}
