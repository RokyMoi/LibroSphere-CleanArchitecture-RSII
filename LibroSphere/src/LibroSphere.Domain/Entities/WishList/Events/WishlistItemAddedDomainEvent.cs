using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.WishList.Events;

public sealed class WishlistItemAddedDomainEvent(Guid wishlistId, Guid userId, Guid bookId) : IDomainEvent
{
    public Guid WishlistId { get; } = wishlistId;
    public Guid UserId { get; } = userId;
    public Guid BookId { get; } = bookId;
}
