using FluentValidation;

namespace LibroSphere.Application.Orders.Command.CreateOrder
{
    public sealed class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
    {
        public CreateOrderCommandValidator()
        {
            RuleFor(x => x.BuyerEmail).NotEmpty().EmailAddress();
            RuleFor(x => x.CartId).NotEmpty();
        }
    }
}
