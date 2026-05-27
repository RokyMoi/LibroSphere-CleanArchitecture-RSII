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
            StripeConfiguration.ApiKey = _config["StripeSettings:SecretKey"];
        }

        public async Task<ShoppingCart?> CreateOrUpdatePaymentIntent(
            string cartId,
            Guid userId,
            string buyerEmail,
            CancellationToken cancellationToken = default)
        {
            var cart = await _cartService.GetCartAsync(cartId);
            if (cart == null) return null;
            if (cart.UserId != userId) return null;
            if (cart.Items.Count == 0) return null;

            var metadata = new Dictionary<string, string>
            {
                { "cartId", cartId },
                { "userId", userId.ToString() },
                { "buyerEmail", buyerEmail }
            };

            var bookIds = cart.Items.Select(i => i.BookId).Distinct().ToList();
            var books = await _bookRepository.GetByIdsWithDetailsAsync(bookIds, cancellationToken);
            var bookLookup = books.ToDictionary(b => b.Id);

            foreach (var item in cart.Items)
            {
                if (!bookLookup.TryGetValue(item.BookId, out var book)) return null;
                if (book.Price != item.Price)
                    item.SetPrice(book.Price);
            }

            var currencyCodes = cart.Items
                .Select(i => i.Price.Currency.Code.ToLowerInvariant())
                .Distinct()
                .ToList();
            if (currencyCodes.Count > 1) return null;
            var currency = currencyCodes.FirstOrDefault() ?? "usd";

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
                    Currency = currency,
                    PaymentMethodTypes = new List<string> { "card" },
                    Metadata = metadata
                };

                intent = await service.CreateAsync(options);
                cart.SetPaymentIntent(intent.Id);
                cart.ClientSecret = intent.ClientSecret;
            }
            else
            {
                var options = new PaymentIntentUpdateOptions
                {
                    Amount = amountInCents,
                    Metadata = metadata
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

            var refundService = new RefundService();
            var trimmedReason = reason?.Trim();
            var options = new RefundCreateOptions
            {
                PaymentIntent = paymentIntentId,
                Amount = amountInCents,
                Reason = "requested_by_customer"
            };

            if (!string.IsNullOrWhiteSpace(trimmedReason))
            {
                options.Metadata = new Dictionary<string, string>
                {
                    { "reason", trimmedReason }
                };
            }

            try
            {
                var refund = await refundService.CreateAsync(options, cancellationToken: cancellationToken);
                return Result.Success(refund.Id);
            }
            catch (StripeException ex) when (ex.StripeError?.Code == "charge_already_refunded")
            {
                return Result.Success("already_refunded");
            }
            catch (StripeException ex)
            {
                return Result.Failure<string>(new Error("Payment.Refund.Failed", ex.Message));
            }
        }
    }
}
