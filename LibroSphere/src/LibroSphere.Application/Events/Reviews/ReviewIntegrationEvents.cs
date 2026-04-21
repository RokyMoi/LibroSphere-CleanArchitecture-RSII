namespace LibroSphere.Application.Events.Reviews;

public sealed class ReviewCreatedIntegrationEvent
{
    public ReviewCreatedIntegrationEvent(Guid reviewId, Guid userId, Guid bookId, int rating)
    {
        ReviewId = reviewId;
        UserId = userId;
        BookId = bookId;
        Rating = rating;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public ReviewCreatedIntegrationEvent()
    {
    }

    public Guid ReviewId { get; init; }
    public Guid UserId { get; init; }
    public Guid BookId { get; init; }
    public int Rating { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}

public sealed class ReviewUpdatedIntegrationEvent
{
    public ReviewUpdatedIntegrationEvent(Guid reviewId, Guid userId, Guid bookId, int rating)
    {
        ReviewId = reviewId;
        UserId = userId;
        BookId = bookId;
        Rating = rating;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public ReviewUpdatedIntegrationEvent()
    {
    }

    public Guid ReviewId { get; init; }
    public Guid UserId { get; init; }
    public Guid BookId { get; init; }
    public int Rating { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}

public sealed class ReviewDeletedIntegrationEvent
{
    public ReviewDeletedIntegrationEvent(Guid reviewId, Guid userId, Guid bookId)
    {
        ReviewId = reviewId;
        UserId = userId;
        BookId = bookId;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public ReviewDeletedIntegrationEvent()
    {
    }

    public Guid ReviewId { get; init; }
    public Guid UserId { get; init; }
    public Guid BookId { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}
