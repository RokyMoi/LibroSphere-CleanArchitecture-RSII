using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Books.Events
{
    public sealed record BookDeletedDomainEvent(Guid BookId, string Title) : IDomainEvent;
}
