using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Authors.Events
{
    public sealed record AuthorCreatedDomainEvent(Guid AuthorId, string Name) : IDomainEvent;
}
