using LibroSphere.Application.Cart.Command.DeleteCart;
using LibroSphere.Application.Cart.Command.UpdateCart;
using LibroSphere.Application.Cart.Query.GetCartDetails;
using LibroSphere.Application.Cart.Query.GetCartById;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Cart
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class CartController : ControllerBase
    {
        private readonly ISender _sender;

        public CartController(ISender sender)
        {
            _sender = sender;
        }

        [HttpGet("{cartId:guid}")]
        public async Task<IActionResult> GetCartById(Guid cartId, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetCartDetailsQuery(cartId), cancellationToken);
            if (result.IsFailure)
            {
                return NotFound(result.Error);
            }

            if (!User.IsAdmin() && result.Value.UserId != User.GetRequiredUserId())
            {
                return Forbid();
            }

            return Ok(result.Value);
        }

        [HttpPost]
        public async Task<IActionResult> UpdateCart([FromBody] UpdateCartRequest request, CancellationToken cancellationToken)
        {
            var currentUserId = User.GetRequiredUserId();
            var command = new UpdateCartCommand(
                request.Id,
                currentUserId,
                request.ClientSecret,
                request.PaymentIntentId,
                request.Items.Select(item => new UpdateCartItemModel(item.BookId, item.Price.Amount, item.Price.CurrencyCode)).ToList());

            var result = await _sender.Send(command, cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpDelete("{cartId:guid}")]
        public async Task<IActionResult> DeleteCart(Guid cartId, CancellationToken cancellationToken)
        {
            var cartResult = await _sender.Send(new GetCartByIdQuery(cartId), cancellationToken);
            if (cartResult.IsFailure)
            {
                return NotFound(cartResult.Error);
            }

            if (!User.IsAdmin() && cartResult.Value.UserId != User.GetRequiredUserId())
            {
                return Forbid();
            }

            var result = await _sender.Send(new DeleteCartCommand(cartId), cancellationToken);
            return result.IsSuccess ? NoContent() : NotFound(result.Error);
        }
    }
}
