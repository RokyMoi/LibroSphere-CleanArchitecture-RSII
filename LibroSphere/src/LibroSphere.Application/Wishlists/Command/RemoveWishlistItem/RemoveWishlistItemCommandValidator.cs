using FluentValidation;

namespace LibroSphere.Application.Wishlists.Command.RemoveWishlistItem
{
    public sealed class RemoveWishlistItemCommandValidator : AbstractValidator<RemoveWishlistItemCommand>
    {
        public RemoveWishlistItemCommandValidator()
        {
            RuleFor(x => x.UserId).NotEmpty();
            RuleFor(x => x.BookId).NotEmpty();
        }
    }
}
