using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Domain.Entities.ManyToMany.Events;

public sealed class UserBookGrantedDomainEvent(Guid userBookId, Guid userId, Guid bookId) : IDomainEvent
{
    public Guid UserBookId { get; } = userBookId;
    public Guid UserId { get; } = userId;
    public Guid BookId { get; } = bookId;
}
