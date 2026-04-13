using FluentValidation;

namespace LibroSphere.Application.Payment.Command.CreateOrUpdatePaymentIntent;

public sealed class CreateOrUpdatePaymentIntentCommandValidator : AbstractValidator<CreateOrUpdatePaymentIntentCommand>
{
    public CreateOrUpdatePaymentIntentCommandValidator()
    {
        RuleFor(x => x.CartId).NotEmpty();
    }
}
