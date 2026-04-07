using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Books.Events
{
    public sealed record BookUpdatedDomainEvent(Guid BookId, string Title) : IDomainEvent;
}
