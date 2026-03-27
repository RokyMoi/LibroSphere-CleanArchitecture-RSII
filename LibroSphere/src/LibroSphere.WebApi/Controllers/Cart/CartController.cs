using LibroSphere.Domain.Entities.ShopCart;
using LibroSphere.Infrastructure.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Infrastructure;

namespace LibroSphere.WebApi.Controllers.Cart
{
    [Route("api/[controller]")]
    [ApiController]
    public class CartController(CartService cartService) : ControllerBase
    {
        [HttpGet]
        //String - > We are using IConnectionMultiplexer (Redis) for storing data about our car :)
        //Guid - > ToString();
        [HttpGet("{cartId:guid}")]
        public async Task<ActionResult<ShoppingCart>> GetCartById(Guid cartId)
        {
            var cart = await cartService.GetCartASync(cartId.ToString());

            if (cart == null)
                return NotFound($"Cart with ID {cartId} not found.");

            return Ok(cart);
        }

        [HttpPost]
        public async Task<ActionResult<ShoppingCart>> UpdateCart(ShoppingCart cart)
        {
            var updated = await cartService.SetCartAsync(cart);
            if (updated == null) return BadRequest("Problem updating cart.");
            return Ok(updated);
        }

        [HttpDelete("{cartId:guid}")]
        public async Task<IActionResult> DeleteCart(Guid cartId)
        {
            var result = await cartService.DeleteCartAsync(cartId.ToString());
            if (!result) return NotFound("Cart not found or already deleted.");
            return NoContent();
        }
    } 
}
