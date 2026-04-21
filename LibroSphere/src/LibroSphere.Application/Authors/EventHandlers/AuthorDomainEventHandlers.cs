using LibroSphere.Application.Events.Authors;
using LibroSphere.Domain.Entities.Authors.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Authors.EventHandlers;

internal sealed class AuthorCreatedDomainEventHandler : INotificationHandler<AuthorCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public AuthorCreatedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(AuthorCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(new AuthorCreatedIntegrationEvent(notification.AuthorId, notification.Name, adminEmail), cancellationToken);
    }
}

internal sealed class AuthorUpdatedDomainEventHandler : INotificationHandler<AuthorUpdatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public AuthorUpdatedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(AuthorUpdatedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(new AuthorUpdatedIntegrationEvent(notification.AuthorId, notification.Name, adminEmail), cancellationToken);
    }
}

internal sealed class AuthorDeletedDomainEventHandler : INotificationHandler<AuthorDeletedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public AuthorDeletedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(AuthorDeletedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(new AuthorDeletedIntegrationEvent(notification.AuthorId, notification.Name, adminEmail), cancellationToken);
    }
}
