using FluentValidation;

namespace LibroSphere.Application.Cart.Command.UpdateCart
{
    public sealed class UpdateCartCommandValidator : AbstractValidator<UpdateCartCommand>
    {
        public UpdateCartCommandValidator()
        {
            RuleFor(x => x.Id).NotEmpty();
            RuleFor(x => x.UserId).NotEmpty();
            RuleFor(x => x.Items).NotEmpty();
            RuleForEach(x => x.Items).ChildRules(item =>
            {
                item.RuleFor(x => x.BookId).NotEmpty();
                item.RuleFor(x => x.Amount).GreaterThan(0);
                item.RuleFor(x => x.CurrencyCode).NotEmpty().MaximumLength(10);
            });
        }
    }
}
