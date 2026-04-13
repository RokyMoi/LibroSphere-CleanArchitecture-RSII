using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.ManyToMany.Events;

public sealed class UserBookGrantedDomainEvent(Guid userBookId, string userEmail, Guid bookId) : IDomainEvent
{
    public Guid UserBookId { get; } = userBookId;
    public string UserEmail { get; } = userEmail;
    public Guid BookId { get; } = bookId;
}
