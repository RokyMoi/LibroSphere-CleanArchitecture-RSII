using FluentValidation;

namespace LibroSphere.Application.Wishlists.Query.GetWishlistByUserId
{
    public sealed class GetWishlistByUserIdQueryValidator : AbstractValidator<GetWishlistByUserIdQuery>
    {
        public GetWishlistByUserIdQueryValidator()
        {
            RuleFor(x => x.UserId).NotEmpty();
        }
    }
}
