namespace LibroSphere.Application.Events.Library;

public sealed class UserBookGrantedIntegrationEvent
{
    public UserBookGrantedIntegrationEvent(Guid userBookId, Guid userId, Guid bookId)
    {
        UserBookId = userBookId;
        UserId = userId;
        BookId = bookId;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public UserBookGrantedIntegrationEvent() { }

    public Guid UserBookId { get; init; }
    public Guid UserId { get; init; }
    public Guid BookId { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}
