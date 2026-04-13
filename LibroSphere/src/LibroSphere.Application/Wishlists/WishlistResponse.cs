namespace LibroSphere.Application.Wishlists
{
    public sealed record WishlistItemResponse(Guid BookId, string Title, string? ImageLink);

    public sealed record WishlistResponse(Guid WishlistId, Guid UserId, List<WishlistItemResponse> Items);
}
