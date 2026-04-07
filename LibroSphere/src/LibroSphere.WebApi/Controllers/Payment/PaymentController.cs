using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Application.Events.Order;
using LibroSphere.Domain.Entities.ManyToMany;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.Domain.Entities.ShopCart;
using MassTransit;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;

namespace LibroSphere.WebApi.Controllers.Payment
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly IOrderRepository _orderRepo;
        private readonly IUserBookRepository _userBookRepo;
        private readonly IConfiguration _config;
        private readonly IPublishEndpoint _publishEndpoint;

        public PaymentController(
            IPaymentService paymentService,
            IOrderRepository orderRepo,
            IUserBookRepository userBookRepo,
            IConfiguration config,
            IPublishEndpoint publishEndpoint)
        {
            _paymentService = paymentService;
            _orderRepo = orderRepo;
            _userBookRepo = userBookRepo;
            _config = config;
            _publishEndpoint = publishEndpoint;
        }

        [HttpPost("{cartId}")]
        [Authorize]
        public async Task<ActionResult<ShoppingCart>> CreateOrUpdatePaymentIntent(string cartId)
        {
            var cart = await _paymentService.CreateOrUpdatePaymentIntent(cartId);
            if (cart == null)
            {
                return BadRequest("Problem with your cart");
            }

            return Ok(cart);
        }

        [HttpPost("webhook")]
        public async Task<IActionResult> StripeWebhook()
        {
            var json = await new StreamReader(Request.Body).ReadToEndAsync();
            var signature = Request.Headers["Stripe-Signature"];
            var secret = _config["StripeSettings:WhSecret"];

            Stripe.Event stripeEvent;
            try
            {
                stripeEvent = EventUtility.ConstructEvent(json, signature, secret);
            }
            catch (StripeException ex)
            {
                return BadRequest($"Webhook error: {ex.Message}");
            }

            switch (stripeEvent.Type)
            {
                case "payment_intent.succeeded":
                    await HandleSucceeded(stripeEvent.Data.Object as PaymentIntent);
                    break;
                case "payment_intent.payment_failed":
                    await HandleFailed(stripeEvent.Data.Object as PaymentIntent);
                    break;
            }

            return Ok();
        }

        private async Task HandleSucceeded(PaymentIntent? intent)
        {
            if (intent == null)
            {
                return;
            }

            var order = await _orderRepo.GetByPaymentIntentIdAsync(intent.Id);
            if (order == null)
            {
                return;
            }

            order.UpdateStatus(OrderStatus.PaymentReceived);

            foreach (var item in order.Items)
            {
                var alreadyHas = await _userBookRepo.HasAccessAsync(order.BuyerEmail, item.BookId);
                if (!alreadyHas)
                {
                    await _userBookRepo.AddAsync(UserBook.Create(order.BuyerEmail, item.BookId));
                }
            }

            await _orderRepo.SaveChangesAsync();
            await _userBookRepo.SaveChangesAsync();

            await _publishEndpoint.Publish(new OrderPaidIntegrationEvent(
                order.Id,
                order.BuyerEmail,
                order.TotalAmount.amount,
                order.TotalAmount.Currency.Code,
                order.Items
                    .Select(item => new OrderPaidItem(
                        item.Title,
                        item.Price.amount,
                        item.Price.Currency.Code,
                        item.Quantity))
                    .ToList()));
        }

        private async Task HandleFailed(PaymentIntent? intent)
        {
            if (intent == null)
            {
                return;
            }

            var order = await _orderRepo.GetByPaymentIntentIdAsync(intent.Id);
            if (order == null)
            {
                return;
            }

            order.UpdateStatus(OrderStatus.PaymentFailed);
            await _orderRepo.SaveChangesAsync();
        }
    }
}
