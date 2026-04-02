using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Entities.ShopCart;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Cart
{
    [Route("api/[controller]")]
    [ApiController]
    public class CartController : ControllerBase
    {
        private readonly ICartService _cartService;

    
        public CartController(ICartService cartService) => _cartService = cartService;

        [HttpGet("{cartId:guid}")]
        public async Task<ActionResult<ShoppingCart>> GetCartById(Guid cartId)
        {
            var cart = await _cartService.GetCartASync(cartId.ToString());
            if (cart == null) return NotFound($"Cart with ID {cartId} not found.");
            return Ok(cart);
        }

        [HttpPost]
        public async Task<ActionResult<ShoppingCart>> UpdateCart(ShoppingCart cart)
        {
            var updated = await _cartService.SetCartAsync(cart);
            if (updated == null) return BadRequest("Problem updating cart.");
            return Ok(updated);
        }

        [HttpDelete("{cartId:guid}")]
        public async Task<IActionResult> DeleteCart(Guid cartId)
        {
            var result = await _cartService.DeleteCartAsync(cartId.ToString());
            if (!result) return NotFound("Cart not found or already deleted.");
            return NoContent();
        }
    }
}