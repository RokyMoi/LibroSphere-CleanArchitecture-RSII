namespace LibroSphere.Application.Events.Books;

public sealed class BookCreatedIntegrationEvent
{
    public BookCreatedIntegrationEvent(Guid bookId, string title, Guid authorId, decimal amount, string currency, string? adminEmail = null)
    {
        BookId = bookId;
        Title = title;
        AuthorId = authorId;
        Amount = amount;
        Currency = currency;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public BookCreatedIntegrationEvent()
    {
        Title = string.Empty;
        Currency = string.Empty;
    }

    public Guid BookId { get; init; }
    public string Title { get; init; }
    public Guid AuthorId { get; init; }
    public decimal Amount { get; init; }
    public string Currency { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}

public sealed class BookUpdatedIntegrationEvent
{
    public BookUpdatedIntegrationEvent(Guid bookId, string title, Guid authorId, decimal amount, string currency, string? adminEmail = null)
    {
        BookId = bookId;
        Title = title;
        AuthorId = authorId;
        Amount = amount;
        Currency = currency;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public BookUpdatedIntegrationEvent()
    {
        Title = string.Empty;
        Currency = string.Empty;
    }

    public Guid BookId { get; init; }
    public string Title { get; init; }
    public Guid AuthorId { get; init; }
    public decimal Amount { get; init; }
    public string Currency { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}

public sealed class BookDeletedIntegrationEvent
{
    public BookDeletedIntegrationEvent(Guid bookId, string title, Guid authorId, string? adminEmail = null)
    {
        BookId = bookId;
        Title = title;
        AuthorId = authorId;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public BookDeletedIntegrationEvent()
    {
        Title = string.Empty;
    }

    public Guid BookId { get; init; }
    public string Title { get; init; }
    public Guid AuthorId { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}
