using LibroSphere.Application.Events.Books;
using LibroSphere.Domain.Entities.Books.Events;
using MassTransit;
using MediatR;

namespace LibroSphere.Application.Books.EventHandlers;

internal sealed class BookCreatedDomainEventHandler : INotificationHandler<BookCreatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public BookCreatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(BookCreatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new BookCreatedIntegrationEvent(notification.BookId, notification.Title, notification.AuthorId, notification.Amount, notification.Currency),
            cancellationToken);
    }
}

internal sealed class BookUpdatedDomainEventHandler : INotificationHandler<BookUpdatedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public BookUpdatedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(BookUpdatedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new BookUpdatedIntegrationEvent(notification.BookId, notification.Title, notification.AuthorId, notification.Amount, notification.Currency),
            cancellationToken);
    }
}

internal sealed class BookDeletedDomainEventHandler : INotificationHandler<BookDeletedDomainEvent>
{
    private readonly IPublishEndpoint _publishEndpoint;

    public BookDeletedDomainEventHandler(IPublishEndpoint publishEndpoint)
    {
        _publishEndpoint = publishEndpoint;
    }

    public Task Handle(BookDeletedDomainEvent notification, CancellationToken cancellationToken)
    {
        return _publishEndpoint.Publish(
            new BookDeletedIntegrationEvent(notification.BookId, notification.Title, notification.AuthorId),
            cancellationToken);
    }
}
