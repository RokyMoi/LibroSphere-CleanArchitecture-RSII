using FluentValidation;

namespace LibroSphere.Application.Wishlists.Command.AddWishlistItem
{
    public sealed class AddWishlistItemCommandValidator : AbstractValidator<AddWishlistItemCommand>
    {
        public AddWishlistItemCommandValidator()
        {
            RuleFor(x => x.UserId).NotEmpty();
            RuleFor(x => x.BookId).NotEmpty();
        }
    }
}
