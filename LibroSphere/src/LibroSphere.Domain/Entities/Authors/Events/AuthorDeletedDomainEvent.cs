using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Authors.Events
{
    public sealed record AuthorDeletedDomainEvent(Guid AuthorId, string Name) : IDomainEvent;
}
