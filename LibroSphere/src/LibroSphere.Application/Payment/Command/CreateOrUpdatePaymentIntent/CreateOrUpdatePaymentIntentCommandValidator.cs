using FluentValidation;

namespace LibroSphere.Application.Payment.Command.CreateOrUpdatePaymentIntent;

public sealed class CreateOrUpdatePaymentIntentCommandValidator : AbstractValidator<CreateOrUpdatePaymentIntentCommand>
{
    public CreateOrUpdatePaymentIntentCommandValidator()
    {
        RuleFor(x => x.CartId).NotEmpty();
        RuleFor(x => x.UserId).NotEmpty();
        RuleFor(x => x.BuyerEmail).NotEmpty().EmailAddress();
    }
}
