using LibroSphere.Application.Events.Reviews;
using LibroSphere.Domain.Entities.Reviews.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Reviews.EventHandlers;

internal sealed class ReviewCreatedDomainEventHandler : INotificationHandler<ReviewCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public ReviewCreatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(ReviewCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new ReviewCreatedIntegrationEvent(notification.ReviewId, notification.UserId, notification.BookId, notification.Rating),
            cancellationToken);
    }
}

internal sealed class ReviewUpdatedDomainEventHandler : INotificationHandler<ReviewUpdatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public ReviewUpdatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(ReviewUpdatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new ReviewUpdatedIntegrationEvent(notification.ReviewId, notification.UserId, notification.BookId, notification.Rating),
            cancellationToken);
    }
}

internal sealed class ReviewDeletedDomainEventHandler : INotificationHandler<ReviewDeletedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public ReviewDeletedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(ReviewDeletedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new ReviewDeletedIntegrationEvent(notification.ReviewId, notification.UserId, notification.BookId),
            cancellationToken);
    }
}
