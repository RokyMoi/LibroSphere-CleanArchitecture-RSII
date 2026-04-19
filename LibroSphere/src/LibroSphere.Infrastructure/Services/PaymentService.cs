using LibroSphere.Application.Abstractions.ShoppingServices;
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
    }
}