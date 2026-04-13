using LibroSphere.Application.Events.Orders;
using LibroSphere.Domain.Entities.Orders.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Orders.EventHandlers;

internal sealed class OrderCreatedDomainEventHandler : INotificationHandler<OrderCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public OrderCreatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(OrderCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new OrderCreatedIntegrationEvent(
                notification.OrderId,
                notification.BuyerEmail,
                notification.TotalAmount,
                notification.Currency,
                notification.ItemCount),
            cancellationToken);
    }
}

internal sealed class OrderStatusChangedDomainEventHandler : INotificationHandler<OrderStatusChangedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public OrderStatusChangedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(OrderStatusChangedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new OrderStatusChangedIntegrationEvent(notification.OrderId, notification.BuyerEmail, notification.Status),
            cancellationToken);
    }
}
