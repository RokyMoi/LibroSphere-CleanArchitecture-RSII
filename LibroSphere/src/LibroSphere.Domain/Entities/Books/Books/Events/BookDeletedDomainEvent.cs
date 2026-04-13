using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Books.Events;

public sealed class BookDeletedDomainEvent(Guid bookId, string title, Guid authorId) : IDomainEvent
{
    public Guid BookId { get; } = bookId;
    public string Title { get; } = title;
    public Guid AuthorId { get; } = authorId;
}
