using LibroSphere.Application.Events.Wishlists;
using LibroSphere.Domain.Entities.WishList.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Wishlists.EventHandlers;

internal sealed class WishlistCreatedDomainEventHandler : INotificationHandler<WishlistCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public WishlistCreatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(WishlistCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new WishlistCreatedIntegrationEvent(notification.WishlistId, notification.UserId), cancellationToken);
    }
}

internal sealed class WishlistItemAddedDomainEventHandler : INotificationHandler<WishlistItemAddedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public WishlistItemAddedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(WishlistItemAddedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new WishlistItemAddedIntegrationEvent(notification.WishlistId, notification.UserId, notification.BookId),
            cancellationToken);
    }
}

internal sealed class WishlistItemRemovedDomainEventHandler : INotificationHandler<WishlistItemRemovedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public WishlistItemRemovedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(WishlistItemRemovedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new WishlistItemRemovedIntegrationEvent(notification.WishlistId, notification.UserId, notification.BookId),
            cancellationToken);
    }
}
