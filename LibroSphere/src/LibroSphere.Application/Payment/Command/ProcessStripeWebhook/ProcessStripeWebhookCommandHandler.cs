using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Payment.Command.ProcessStripeWebhook;

internal sealed class ProcessStripeWebhookCommandHandler : ICommandHandler<ProcessStripeWebhookCommand>
{
    private readonly IPaymentWebhookProcessor _paymentWebhookProcessor;

    public ProcessStripeWebhookCommandHandler(IPaymentWebhookProcessor paymentWebhookProcessor)
    {
        _paymentWebhookProcessor = paymentWebhookProcessor;
    }

    public Task<Result> Handle(ProcessStripeWebhookCommand request, CancellationToken cancellationToken)
    {
        return _paymentWebhookProcessor.ProcessAsync(
            request.Json,
            request.Signature,
            request.WebhookSecret,
            cancellationToken);
    }
}
