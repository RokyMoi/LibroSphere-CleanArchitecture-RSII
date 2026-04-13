using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Application.Abstractions.ShoppingServices;

public interface IPaymentWebhookProcessor
{
    Task<Result> ProcessAsync(string json, string signature, string webhookSecret, CancellationToken cancellationToken = default);
}
