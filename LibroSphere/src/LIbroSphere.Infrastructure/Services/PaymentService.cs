using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Entities.Books;
using LibroSphere.Domain.Entities.ShopCart;
using MassTransit.Middleware;
using Microsoft.Extensions.Configuration;
using Stripe;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Metadata.Ecma335;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Infrastructure.Services
{
    public class PaymentService : IPaymentService
    {
        public readonly IConfiguration config;

      

        public readonly IBookRepository _bookRepository;

    

        public readonly ICartService _cartService;

        public PaymentService(IConfiguration _config,ICartService cartService, IBookRepository bookRepo)
        {
             config = _config;
            _cartService = cartService;
            _bookRepository = bookRepo;
        }
        public async Task<ShoppingCart> CreateOrUpdatePaymentIntent(string cartId)
        {
            StripeConfiguration.ApiKey = config["StripeSettings:SecretKey"];
            var cart = await _cartService.GetCartASync(cartId);

            if(cart == null)
            {
                return null;
            }
            foreach(var item in cart.Items)
            {
                var productItem = await _bookRepository.GetAsyncById(item.Id);
                if (productItem == null)
                {
                    return null;
                }
                if (productItem.Price != item.Price)
                {
                    item.SetPrice(productItem.Price);
                }
            }

            var service = new PaymentIntentService();
            PaymentIntent? intent = null;

            if (string.IsNullOrEmpty(cart.PaymentIntentId)) {

                var options = new PaymentIntentCreateOptions()
                {
                    //decimal to long, because stripe only accepts long type
                    Amount = (long)Math.Round(cart.Items.Sum(x => x.Price.amount * 100m)),
                    Currency = "usd",
                    PaymentMethodTypes = new List<string> { "card" }

                };

                intent = await service.CreateAsync(options);
                cart.SetPaymentIntent(intent.Id);
                cart.ClientSecret = intent.ClientSecret;
            }
            else
            {
                var options = new PaymentIntentUpdateOptions()
                {
                    Amount = (long)Math.Round(cart.Items.Sum(x => x.Price.amount * 100m)),
                    Currency = "usd",
                    PaymentMethodTypes = new List<string> { "card" }
                };
                intent = await service.UpdateAsync(cart.PaymentIntentId,options);
            }
            await _cartService.SetCartAsync(cart);
            return cart;
        }
    }
}
