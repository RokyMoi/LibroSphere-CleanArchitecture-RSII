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

    public Guid UserBookId { get; private set; }
    public string UserEmail { get; private set; }
    public Guid BookId { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
