using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Authors.Events;

public sealed class AuthorUpdatedDomainEvent(Guid authorId, string name) : IDomainEvent
{
    public Guid AuthorId { get; } = authorId;
    public string Name { get; } = name;
}
