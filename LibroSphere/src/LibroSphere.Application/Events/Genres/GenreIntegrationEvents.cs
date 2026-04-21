namespace LibroSphere.Application.Events.Genres;

public sealed class GenreCreatedIntegrationEvent
{
    public GenreCreatedIntegrationEvent(Guid genreId, string name, string? adminEmail = null)
    {
        GenreId = genreId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public GenreCreatedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid GenreId { get; init; }
    public string Name { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}

public sealed class GenreUpdatedIntegrationEvent
{
    public GenreUpdatedIntegrationEvent(Guid genreId, string name, string? adminEmail = null)
    {
        GenreId = genreId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public GenreUpdatedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid GenreId { get; init; }
    public string Name { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}

public sealed class GenreDeletedIntegrationEvent
{
    public GenreDeletedIntegrationEvent(Guid genreId, string name, string? adminEmail = null)
    {
        GenreId = genreId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
        AdminEmail = adminEmail;
    }

    public GenreDeletedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid GenreId { get; init; }
    public string Name { get; init; }
    public DateTime OccurredOnUtc { get; init; }
    public string? AdminEmail { get; init; }
}
