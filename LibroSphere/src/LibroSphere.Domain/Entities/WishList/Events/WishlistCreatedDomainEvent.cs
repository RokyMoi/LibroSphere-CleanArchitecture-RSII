using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Domain.Entities.WishList.Events;

public sealed class WishlistCreatedDomainEvent(Guid wishlistId, Guid userId) : IDomainEvent
{
    public Guid WishlistId { get; } = wishlistId;
    public Guid UserId { get; } = userId;
}
