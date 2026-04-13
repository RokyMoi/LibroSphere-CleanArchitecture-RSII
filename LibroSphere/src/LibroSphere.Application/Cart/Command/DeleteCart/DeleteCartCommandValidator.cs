using FluentValidation;

namespace LibroSphere.Application.Cart.Command.DeleteCart
{
    public sealed class DeleteCartCommandValidator : AbstractValidator<DeleteCartCommand>
    {
        public DeleteCartCommandValidator()
        {
            RuleFor(x => x.CartId).NotEmpty();
        }
    }
}
