using FluentValidation;

namespace LibroSphere.Application.Orders.Command.CreateOrder
{
    public sealed class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
    {
        public CreateOrderCommandValidator()
        {
            RuleFor(x => x.BuyerEmail).NotEmpty().MaximumLength(256).EmailAddress();
            RuleFor(x => x.UserId).NotEmpty();
            RuleFor(x => x.CartId).NotEmpty();
            RuleFor(x => x.PaymentIntentId).NotEmpty().MaximumLength(200);
        }
    }
}
