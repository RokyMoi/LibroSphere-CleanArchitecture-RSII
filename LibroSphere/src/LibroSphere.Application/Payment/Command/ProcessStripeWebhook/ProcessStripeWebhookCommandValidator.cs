using FluentValidation;

namespace LibroSphere.Application.Payment.Command.ProcessStripeWebhook;

public sealed class ProcessStripeWebhookCommandValidator : AbstractValidator<ProcessStripeWebhookCommand>
{
    public ProcessStripeWebhookCommandValidator()
    {
        RuleFor(x => x.Json).NotEmpty();
        RuleFor(x => x.Signature).NotEmpty();
        RuleFor(x => x.WebhookSecret).NotEmpty();
    }
}
