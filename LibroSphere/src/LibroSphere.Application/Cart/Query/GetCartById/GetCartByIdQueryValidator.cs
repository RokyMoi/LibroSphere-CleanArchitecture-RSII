using FluentValidation;

namespace LibroSphere.Application.Cart.Query.GetCartById
{
    public sealed class GetCartByIdQueryValidator : AbstractValidator<GetCartByIdQuery>
    {
        public GetCartByIdQueryValidator()
        {
            RuleFor(x => x.CartId).NotEmpty();
        }
    }
}
