using LibroSphere.Application.Abstractions.Events.DomainEvent;

namespace LibroSphere.Domain.Entities.WishList.Events
{
    public sealed record WishlistItemAddedDomainEvent(Guid WishlistId, Guid UserId, Guid BookId) : IDomainEvent;
}
