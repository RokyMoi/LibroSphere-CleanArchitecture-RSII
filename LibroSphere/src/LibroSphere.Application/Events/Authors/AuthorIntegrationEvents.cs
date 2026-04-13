namespace LibroSphere.Application.Events.Authors;

public sealed class AuthorCreatedIntegrationEvent
{
    public AuthorCreatedIntegrationEvent(Guid authorId, string name)
    {
        AuthorId = authorId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
    }

    protected AuthorCreatedIntegrationEvent()
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

    protected AuthorUpdatedIntegrationEvent()
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

    protected AuthorDeletedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid AuthorId { get; private set; }
    public string Name { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
