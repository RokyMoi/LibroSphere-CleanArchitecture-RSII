namespace LibroSphere.Application.Events.Library;

public sealed class UserBookGrantedIntegrationEvent
{
    public UserBookGrantedIntegrationEvent(Guid userBookId, string userEmail, Guid bookId)
    {
        UserBookId = userBookId;
        UserEmail = userEmail;
        BookId = bookId;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public UserBookGrantedIntegrationEvent()
    {
        UserEmail = string.Empty;
    }

    public Guid UserBookId { get; init; }
    public string UserEmail { get; init; }
    public Guid BookId { get; init; }
    public DateTime OccurredOnUtc { get; init; }
}
