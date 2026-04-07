using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.Books.Events
{
    public sealed record BookCreatedDomainEvent(Guid BookId, string Title) : IDomainEvent;
}
