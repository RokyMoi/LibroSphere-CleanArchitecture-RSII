using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Reviews.Events
{
    public sealed record ReviewDeletedDomainEvent(Guid ReviewId, Guid BookId, Guid UserId) : IDomainEvent;
}
