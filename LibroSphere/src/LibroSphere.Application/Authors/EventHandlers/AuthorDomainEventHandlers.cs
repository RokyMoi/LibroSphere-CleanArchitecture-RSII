using LibroSphere.Application.Events.Authors;
using LibroSphere.Domain.Entities.Authors.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Authors.EventHandlers;

internal sealed class AuthorCreatedDomainEventHandler : INotificationHandler<AuthorCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public AuthorCreatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(AuthorCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new AuthorCreatedIntegrationEvent(notification.AuthorId, notification.Name), cancellationToken);
    }
}

internal sealed class AuthorUpdatedDomainEventHandler : INotificationHandler<AuthorUpdatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public AuthorUpdatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(AuthorUpdatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new AuthorUpdatedIntegrationEvent(notification.AuthorId, notification.Name), cancellationToken);
    }
}

internal sealed class AuthorDeletedDomainEventHandler : INotificationHandler<AuthorDeletedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public AuthorDeletedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(AuthorDeletedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new AuthorDeletedIntegrationEvent(notification.AuthorId, notification.Name), cancellationToken);
    }
}
