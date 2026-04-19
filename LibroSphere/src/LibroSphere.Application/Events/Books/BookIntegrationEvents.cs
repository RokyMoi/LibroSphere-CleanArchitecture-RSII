namespace LibroSphere.Application.Events.Books;

public sealed class BookCreatedIntegrationEvent
{
    public BookCreatedIntegrationEvent(Guid bookId, string title, Guid authorId, decimal amount, string currency)
    {
        BookId = bookId;
        Title = title;
        AuthorId = authorId;
        Amount = amount;
        Currency = currency;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public BookCreatedIntegrationEvent()
    {
        Title = string.Empty;
        Currency = string.Empty;
    }

    public Guid BookId { get; private set; }
    public string Title { get; private set; }
    public Guid AuthorId { get; private set; }
    public decimal Amount { get; private set; }
    public string Currency { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class BookUpdatedIntegrationEvent
{
    public BookUpdatedIntegrationEvent(Guid bookId, string title, Guid authorId, decimal amount, string currency)
    {
        BookId = bookId;
        Title = title;
        AuthorId = authorId;
        Amount = amount;
        Currency = currency;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public BookUpdatedIntegrationEvent()
    {
        Title = string.Empty;
        Currency = string.Empty;
    }

    public Guid BookId { get; private set; }
    public string Title { get; private set; }
    public Guid AuthorId { get; private set; }
    public decimal Amount { get; private set; }
    public string Currency { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class BookDeletedIntegrationEvent
{
    public BookDeletedIntegrationEvent(Guid bookId, string title, Guid authorId)
    {
        BookId = bookId;
        Title = title;
        AuthorId = authorId;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public BookDeletedIntegrationEvent()
    {
        Title = string.Empty;
    }

    public Guid BookId { get; private set; }
    public string Title { get; private set; }
    public Guid AuthorId { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
