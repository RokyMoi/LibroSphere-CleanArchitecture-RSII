using LibroSphere.Application.Orders.Command.CreateOrder;
using LibroSphere.Application.Orders.Query.GetMyOrders;
using LibroSphere.Application.Orders.Query.GetOrderById;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.WebApi.Extensions;
using LibroSphere.Domain.Entities.Orders;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LibroSphere.WebApi.Controllers.Orders
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class OrdersController : ControllerBase
    {
        private readonly ISender _sender;

        public OrdersController(ISender sender)
        {
            _sender = sender;
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest dto, CancellationToken cancellationToken)
        {
            var email = User.GetRequiredEmail();
            var result = await _sender.Send(new CreateOrderCommand(email, dto.CartId), cancellationToken);
            return result.IsSuccess
                ? CreatedAtAction(nameof(GetOrder), new { id = result.Value.Id }, result.Value)
                : BadRequest(result.Error);
        }

        [HttpGet]
        public async Task<IActionResult> GetMyOrders(
            [FromQuery] OrderStatus? status,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            CancellationToken cancellationToken = default)
        {
            var email = User.GetRequiredEmail();
            var result = await _sender.Send(new GetMyOrdersQuery(email, status, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetOrder(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetOrderByIdQuery(id), cancellationToken);
            if (result.IsFailure)
            {
                return NotFound(result.Error);
            }

            if (!User.IsAdmin() && !string.Equals(result.Value.BuyerEmail, User.GetRequiredEmail(), StringComparison.OrdinalIgnoreCase))
            {
                return Forbid();
            }

            return Ok(result.Value);
        }
    }
}
