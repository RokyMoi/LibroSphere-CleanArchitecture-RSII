using LibroSphere.Application.Events.Genres;
using LibroSphere.Domain.Entities.Books.Genre.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Genres.EventHandlers;

internal sealed class GenreCreatedDomainEventHandler : INotificationHandler<GenreCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public GenreCreatedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(GenreCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(new GenreCreatedIntegrationEvent(notification.GenreId, notification.Name, adminEmail), cancellationToken);
    }
}

internal sealed class GenreUpdatedDomainEventHandler : INotificationHandler<GenreUpdatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public GenreUpdatedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(GenreUpdatedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(new GenreUpdatedIntegrationEvent(notification.GenreId, notification.Name, adminEmail), cancellationToken);
    }
}

internal sealed class GenreDeletedDomainEventHandler : INotificationHandler<GenreDeletedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public GenreDeletedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(GenreDeletedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(new GenreDeletedIntegrationEvent(notification.GenreId, notification.Name, adminEmail), cancellationToken);
    }
}
