using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Books.Genre.Events;

public sealed class GenreDeletedDomainEvent(Guid genreId, string name) : IDomainEvent
{
    public Guid GenreId { get; } = genreId;
    public string Name { get; } = name;
}
