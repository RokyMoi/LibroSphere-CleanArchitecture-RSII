using LibroSphere.Application.Events.Genres;
using LibroSphere.Domain.Entities.Books.Genre.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Genres.EventHandlers;

internal sealed class GenreCreatedDomainEventHandler : INotificationHandler<GenreCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public GenreCreatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(GenreCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new GenreCreatedIntegrationEvent(notification.GenreId, notification.Name), cancellationToken);
    }
}

internal sealed class GenreUpdatedDomainEventHandler : INotificationHandler<GenreUpdatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public GenreUpdatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(GenreUpdatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new GenreUpdatedIntegrationEvent(notification.GenreId, notification.Name), cancellationToken);
    }
}

internal sealed class GenreDeletedDomainEventHandler : INotificationHandler<GenreDeletedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public GenreDeletedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(GenreDeletedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(new GenreDeletedIntegrationEvent(notification.GenreId, notification.Name), cancellationToken);
    }
}
