using LibroSphere.Application.Events.User;
using LibroSphere.Domain.Entities.Users.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Users.DomainEventHandler;

internal sealed class UserCreatedDomainEventHandler
    : INotificationHandler<UserCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public UserCreatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(
        UserCreatedDomainEvent notification,
        CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new UserCreatedIntegrationEvent(notification.UserId, notification.Email),
            cancellationToken);
    }
}