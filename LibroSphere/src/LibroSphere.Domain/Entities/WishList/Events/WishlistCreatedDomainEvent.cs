using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.WishList.Events;

public sealed class WishlistCreatedDomainEvent(Guid wishlistId, Guid userId) : IDomainEvent
{
    public Guid WishlistId { get; } = wishlistId;
    public Guid UserId { get; } = userId;
}
