using LibroSphere.Application.Events.Library;
using LibroSphere.Domain.Entities.ManyToMany.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Library.EventHandlers;

internal sealed class UserBookGrantedDomainEventHandler : INotificationHandler<UserBookGrantedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public UserBookGrantedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(UserBookGrantedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new UserBookGrantedIntegrationEvent(notification.UserBookId, notification.UserEmail, notification.BookId),
            cancellationToken);
    }
}
