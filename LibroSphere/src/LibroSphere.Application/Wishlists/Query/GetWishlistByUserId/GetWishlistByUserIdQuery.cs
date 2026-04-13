using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Wishlists.Query.GetWishlistByUserId
{
    public sealed record GetWishlistByUserIdQuery(Guid UserId) : IQuery<WishlistResponse>;
}
