using LibroSphere.Application.Events.Users;
using LibroSphere.Domain.Entities.Users.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Users.EventHandlers;

internal sealed class UserLoggedInDomainEventHandler : INotificationHandler<UserLoggedInDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public UserLoggedInDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(UserLoggedInDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new UserLoggedInIntegrationEvent(notification.UserId, notification.Email), cancellationToken);
    }
}

internal sealed class UserDeactivatedDomainEventHandler : INotificationHandler<UserDeactivatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public UserDeactivatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(UserDeactivatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new UserDeactivatedIntegrationEvent(notification.UserId, notification.Email), cancellationToken);
    }
}
