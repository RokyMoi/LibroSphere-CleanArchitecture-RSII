namespace LibroSphere.Application.Events.Wishlists;

public sealed class WishlistCreatedIntegrationEvent
{
    public WishlistCreatedIntegrationEvent(Guid wishlistId, Guid userId)
    {
        WishlistId = wishlistId;
        UserId = userId;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public WishlistCreatedIntegrationEvent()
    {
    }

    public Guid WishlistId { get; private set; }
    public Guid UserId { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class WishlistItemAddedIntegrationEvent
{
    public WishlistItemAddedIntegrationEvent(Guid wishlistId, Guid userId, Guid bookId)
    {
        WishlistId = wishlistId;
        UserId = userId;
        BookId = bookId;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public WishlistItemAddedIntegrationEvent()
    {
    }

    public Guid WishlistId { get; private set; }
    public Guid UserId { get; private set; }
    public Guid BookId { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}

public sealed class WishlistItemRemovedIntegrationEvent
{
    public WishlistItemRemovedIntegrationEvent(Guid wishlistId, Guid userId, Guid bookId)
    {
        WishlistId = wishlistId;
        UserId = userId;
        BookId = bookId;
        OccurredOnUtc = DateTime.UtcNow;
    }

    public WishlistItemRemovedIntegrationEvent()
    {
    }

    public Guid WishlistId { get; private set; }
    public Guid UserId { get; private set; }
    public Guid BookId { get; private set; }
    public DateTime OccurredOnUtc { get; private set; }
}
