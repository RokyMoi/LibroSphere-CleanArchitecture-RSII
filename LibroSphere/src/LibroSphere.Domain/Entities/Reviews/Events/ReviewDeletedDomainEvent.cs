using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Reviews.Events;

public sealed class ReviewDeletedDomainEvent(Guid reviewId, Guid userId, Guid bookId) : IDomainEvent
{
    public Guid ReviewId { get; } = reviewId;
    public Guid UserId { get; } = userId;
    public Guid BookId { get; } = bookId;
}
