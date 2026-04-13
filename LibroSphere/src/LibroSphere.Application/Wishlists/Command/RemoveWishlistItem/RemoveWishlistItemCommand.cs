using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Wishlists.Command.RemoveWishlistItem
{
    public sealed record RemoveWishlistItemCommand(Guid UserId, Guid BookId) : ICommand;
}
