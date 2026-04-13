namespace LibroSphere.Application.Events.Genres;

public sealed class GenreCreatedIntegrationEvent
{
    public GenreCreatedIntegrationEvent(Guid genreId, string name)
    {
        GenreId = genreId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
    }

    protected GenreCreatedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid GenreId { get; private set; }
    public string Name { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class GenreUpdatedIntegrationEvent
{
    public GenreUpdatedIntegrationEvent(Guid genreId, string name)
    {
        GenreId = genreId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
    }

    protected GenreUpdatedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid GenreId { get; private set; }
    public string Name { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class GenreDeletedIntegrationEvent
{
    public GenreDeletedIntegrationEvent(Guid genreId, string name)
    {
        GenreId = genreId;
        Name = name;
        OccurredOnUtc = DateTime.UtcNow;
    }

    protected GenreDeletedIntegrationEvent()
    {
        Name = string.Empty;
    }

    public Guid GenreId { get; private set; }
    public string Name { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
