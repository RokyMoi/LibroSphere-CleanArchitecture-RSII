using LibroSphere.Application.Events.Books;
using LibroSphere.Domain.Entities.Books.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Books.EventHandlers;

internal sealed class BookCreatedDomainEventHandler : INotificationHandler<BookCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public BookCreatedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(BookCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(
            new BookCreatedIntegrationEvent(notification.BookId, notification.Title, notification.AuthorId, notification.Amount, notification.Currency, adminEmail),
            cancellationToken);
    }
}

internal sealed class BookUpdatedDomainEventHandler : INotificationHandler<BookUpdatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public BookUpdatedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(BookUpdatedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(
            new BookUpdatedIntegrationEvent(notification.BookId, notification.Title, notification.AuthorId, notification.Amount, notification.Currency, adminEmail),
            cancellationToken);
    }
}

internal sealed class BookDeletedDomainEventHandler : INotificationHandler<BookDeletedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly LibroSphere.Application.Abstractions.Identity.IUserContext _userContext;

    public BookDeletedDomainEventHandler(IPublishEndpoint publishEndpoint, LibroSphere.Application.Abstractions.Identity.IUserContext userContext)
    {
        _publishEndpoint = publishEndpoint;
        _userContext = userContext;
    }

    public Task Handle(BookDeletedDomainEvent notification, CancellationToken cancellationToken)
    {
        var adminEmail = _userContext.IsAdmin ? _userContext.Email : null;
        return _publishEndpoint.Publish(
            new BookDeletedIntegrationEvent(notification.BookId, notification.Title, notification.AuthorId, adminEmail),
            cancellationToken);
    }
}
