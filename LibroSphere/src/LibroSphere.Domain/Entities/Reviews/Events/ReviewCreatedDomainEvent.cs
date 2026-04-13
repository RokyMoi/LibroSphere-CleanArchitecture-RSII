using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Reviews.Events;

public sealed class ReviewCreatedDomainEvent(Guid reviewId, Guid userId, Guid bookId, int rating) : IDomainEvent
{
    public Guid ReviewId { get; } = reviewId;
    public Guid UserId { get; } = userId;
    public Guid BookId { get; } = bookId;
    public int Rating { get; } = rating;
}
