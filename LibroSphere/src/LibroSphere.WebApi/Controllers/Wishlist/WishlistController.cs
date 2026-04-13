using LibroSphere.Application.Wishlists.Command.AddWishlistItem;
using LibroSphere.Application.Wishlists.Command.RemoveWishlistItem;
using LibroSphere.Application.Wishlists.Query.GetWishlistByUserId;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Wishlist
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class WishlistController : ControllerBase
    {
        private readonly ISender _sender;

        public WishlistController(ISender sender)
        {
            _sender = sender;
        }

        [HttpGet]
        public async Task<IActionResult> GetMine(CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new GetWishlistByUserIdQuery(userId), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : NotFound(result.Error);
        }

        [HttpPost]
        public async Task<IActionResult> AddItem([FromBody] WishlistItemRequest request, CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new AddWishlistItemCommand(userId, request.BookId), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }

        [HttpDelete("{bookId:guid}")]
        public async Task<IActionResult> RemoveItem(Guid bookId, CancellationToken cancellationToken)
        {
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new RemoveWishlistItemCommand(userId, bookId), cancellationToken);
            return result.IsSuccess ? NoContent() : BadRequest(result.Error);
        }
    }
}
