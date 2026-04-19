namespace LibroSphere.Application.Events.Authors;

public sealed class AuthorCreatedIntegrationEvent
{
    public AuthorCreatedIntegrationEvent(Guid authorId, string name)
    {
        AuthorId = authorId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public AuthorCreatedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid AuthorId { get; private set; }
    public string Name { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class AuthorUpdatedIntegrationEvent
{
    public AuthorUpdatedIntegrationEvent(Guid authorId, string name)
    {
        AuthorId = authorId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public AuthorUpdatedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid AuthorId { get; private set; }
    public string Name { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class AuthorDeletedIntegrationEvent
{
    public AuthorDeletedIntegrationEvent(Guid authorId, string name)
    {
        AuthorId = authorId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public AuthorDeletedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid AuthorId { get; private set; }
    public string Name { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
