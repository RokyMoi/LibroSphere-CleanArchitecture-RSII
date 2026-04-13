using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Books.Events;

public sealed class BookCreatedDomainEvent(Guid bookId, string title, Guid authorId, decimal amount, string currency) : IDomainEvent
{
    public Guid BookId { get; } = bookId;
    public string Title { get; } = title;
    public Guid AuthorId { get; } = authorId;
    public decimal Amount { get; } = amount;
    public string Currency { get; } = currency;
}
