using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Domain.Entities.Authors.Events;

public sealed class AuthorCreatedDomainEvent(Guid authorId, string name) : IDomainEvent
{
    public Guid AuthorId { get; } = authorId;
    public string Name { get; } = name;
}
