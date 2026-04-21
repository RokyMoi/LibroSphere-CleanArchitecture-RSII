using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ShopCart;
using Microsoft.Extensions.Configuration;
using Stripe;

namespace LibroSphere.Infrastructure.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly IConfiguration _config;
        private readonly IBookRepository _bookRepository;
        private readonly ICartService _cartService;

        public PaymentService(IConfiguration config, ICartService cartService, IBookRepository bookRepo)
        {
            _config = config;
            _cartService = cartService;
            _bookRepository = bookRepo;
        }

        public async Task<ShoppingCart?> CreateOrUpdatePaymentIntent(string cartId)
        {
            StripeConfiguration.ApiKey = _config["StripeSettings:SecretKey"];

            var cart = await _cartService.GetCartASync(cartId);
            if (cart == null) return null;

            foreach (var item in cart.Items)
            {
                var book = await _bookRepository.GetAsyncById(item.BookId);
                if (book == null) return null;

                if (book.Price != item.Price)
                    item.SetPrice(book.Price);
            }

            var service = new PaymentIntentService();
            PaymentIntent intent;

            var amountInCents = (long)Math.Round(
                cart.Items.Sum(x => x.Price.amount * 100m)
            );

            if (string.IsNullOrEmpty(cart.PaymentIntentId))
            {
                var options = new PaymentIntentCreateOptions
                {
                    Amount = amountInCents,
                    Currency = "usd",
                    PaymentMethodTypes = new List<string> { "card" },
                    Metadata = new Dictionary<string, string>
                    {
                        { "cartId", cartId }
                    }
                };

                intent = await service.CreateAsync(options);
                cart.SetPaymentIntent(intent.Id);
                cart.ClientSecret = intent.ClientSecret;
            }
            else
            {
                var options = new PaymentIntentUpdateOptions
                {
                    Amount = amountInCents
                };
                intent = await service.UpdateAsync(cart.PaymentIntentId, options);

                cart.ClientSecret = intent.ClientSecret;
            }

            await _cartService.SetCartAsync(cart);
            return cart;
        }

        public async Task<Result<string>> RefundPaymentIntentAsync(
            string paymentIntentId,
            long? amountInCents = null,
            string? reason = null,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(paymentIntentId))
            {
                return Result.Failure<string>(new Error("Payment.Refund.InvalidIntent", "Payment intent id is required for refund."));
            }

            StripeConfiguration.ApiKey = _config["StripeSettings:SecretKey"];

            var refundService = new RefundService();
            var options = new RefundCreateOptions
            {
                PaymentIntent = paymentIntentId,
                Amount = amountInCents,
                Reason = "requested_by_customer",
                Metadata = string.IsNullOrWhiteSpace(reason)
                    ? null
                    : new Dictionary<string, string> { { "reason", reason.Trim() } }
            };

            try
            {
                var refund = await refundService.CreateAsync(options, cancellationToken: cancellationToken);
                return Result.Success(refund.Id);
            }
            catch (StripeException ex)
            {
                return Result.Failure<string>(new Error("Payment.Refund.Failed", ex.Message));
            }
        }
    }
}
