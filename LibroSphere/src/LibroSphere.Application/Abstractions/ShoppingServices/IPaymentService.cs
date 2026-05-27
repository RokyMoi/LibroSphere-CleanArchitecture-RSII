using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ShopCart;

namespace LibroSphere.Application.Abstractions.ShoppingServices
{
    public interface IPaymentService
    {
        Task<ShoppingCart?> CreateOrUpdatePaymentIntent(
            string cartId,
            Guid userId,
            string buyerEmail,
            CancellationToken cancellationToken = default);

        Task<Result<string>> RefundPaymentIntentAsync(
            string paymentIntentId,
            long? amountInCents = null,
            string? reason = null,
            CancellationToken cancellationToken = default);
    }
}
