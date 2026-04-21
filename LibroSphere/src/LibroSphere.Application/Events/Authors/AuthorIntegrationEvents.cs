namespace LibroSphere.Application.Events.Authors;

public sealed class AuthorCreatedIntegrationEvent
{
    public AuthorCreatedIntegrationEvent(Guid authorId, string name, string? adminEmail = null)
    {
        AuthorId = authorId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public AuthorCreatedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid AuthorId { get; init; }
    public string Name { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}

public sealed class AuthorUpdatedIntegrationEvent
{
    public AuthorUpdatedIntegrationEvent(Guid authorId, string name, string? adminEmail = null)
    {
        AuthorId = authorId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public AuthorUpdatedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid AuthorId { get; init; }
    public string Name { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}

public sealed class AuthorDeletedIntegrationEvent
{
    public AuthorDeletedIntegrationEvent(Guid authorId, string name, string? adminEmail = null)
    {
        AuthorId = authorId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public AuthorDeletedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid AuthorId { get; init; }
    public string Name { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}
