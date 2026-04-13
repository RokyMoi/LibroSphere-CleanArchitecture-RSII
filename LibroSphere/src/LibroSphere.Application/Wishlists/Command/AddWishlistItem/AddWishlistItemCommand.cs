using LibroSphere.Application.Abstractions.Messaging;

namespace LibroSphere.Application.Wishlists.Command.AddWishlistItem
{
    public sealed record AddWishlistItemCommand(Guid UserId, Guid BookId) : ICommand;
}
