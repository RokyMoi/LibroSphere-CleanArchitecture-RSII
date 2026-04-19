using LibroSphere.Application.Payment.Command.CreateOrUpdatePaymentIntent;
using LibroSphere.Application.Payment.Command.ProcessStripeWebhook;
using LibroSphere.Application.Cart.Query.GetCartById;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Payment
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentController : ControllerBase
    {
        private readonly ISender _sender;
        private readonly IConfiguration _configuration;

        public PaymentController(ISender sender, IConfiguration configuration)
        {
            _sender = sender;
            _configuration = configuration;
        }

        [HttpGet("config")]
        [AllowAnonymous]
        public IActionResult GetClientConfig()
        {
            return Ok(new
            {
                publishableKey = _configuration["StripeSettings:PublishableKey"] ?? string.Empty
            });
        }

        [HttpPost("{cartId}")]
        [Authorize]
        public async Task<IActionResult> CreateOrUpdatePaymentIntent(string cartId, CancellationToken cancellationToken)
        {
            if (Guid.TryParse(cartId, out var parsedCartId))
            {
                var cartResult = await _sender.Send(new GetCartByIdQuery(parsedCartId), cancellationToken);
                if (cartResult.IsFailure)
                {
                    return NotFound(cartResult.Error);
                }

                if (!User.IsAdmin() && cartResult.Value.UserId != User.GetRequiredUserId())
                {
                    return Forbid();
                }
            }

            var result = await _sender.Send(new CreateOrUpdatePaymentIntentCommand(cartId), cancellationToken);

            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpPost("webhook")]
        public async Task<IActionResult> StripeWebhook(CancellationToken cancellationToken)
        {
            var json = await new StreamReader(Request.Body).ReadToEndAsync(cancellationToken);
            var signature = Request.Headers["Stripe-Signature"].ToString();
            var secret = _configuration["StripeSettings:WhSecret"] ?? string.Empty;

            var result = await _sender.Send(new ProcessStripeWebhookCommand(json, signature, secret), cancellationToken);

            return result.IsSuccess ? Ok() : BadRequest($"Webhook error: {result.Error.Message}");
        }
    }
}
