using LibroSphere.Application.Orders.Command.CreateOrder;
using LibroSphere.Application.Orders.Command.RefundOrder;
using LibroSphere.Application.Orders.Command.RequestRefund;
using LibroSphere.Application.Orders.Command.RejectRefund;
using LibroSphere.Application.Orders.Query.GetAllOrders;
using LibroSphere.Application.Orders.Query.GetMyOrders;
using LibroSphere.Application.Orders.Query.GetOrderById;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Domain.Entities.Orders;
using LibroSphere.WebApi.Extensions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

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
        [EnableRateLimiting("write")]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest dto, CancellationToken cancellationToken)
        {
            var email = User.GetRequiredEmail();
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(
                new CreateOrderCommand(email, userId, dto.CartId, dto.PaymentIntentId),
                cancellationToken);
            return result.IsSuccess
                ? CreatedAtAction(nameof(GetOrder), new { id = result.Value.Id }, OrderDetailsResponse.FromOrder(result.Value))
                : result.Error.Code switch
                {
                    "Order.Cart.Forbidden" => Forbid(),
                    "Order.Cart.NotFound" => NotFound(result.Error),
                    _ => BadRequest(result.Error)
                };
        }

        [HttpGet]
        public async Task<IActionResult> GetMyOrders(
            [FromQuery] OrderStatus? status,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            CancellationToken cancellationToken = default)
        {
            pageSize = Math.Clamp(pageSize, 1, 100);
            var userId = User.GetRequiredUserId();
            var result = await _sender.Send(new GetMyOrdersQuery(userId, status, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [Authorize(Roles = ApplicationRoles.Admin)]
        [HttpGet("all")]
        public async Task<IActionResult> GetAllOrders(
            [FromQuery] string? searchTerm,
            [FromQuery] OrderStatus? status,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20,
            CancellationToken cancellationToken = default)
        {
            pageSize = Math.Clamp(pageSize, 1, 100);
            var result = await _sender.Send(new GetAllOrdersQuery(searchTerm, status, page, pageSize), cancellationToken);
            return result.IsSuccess ? Ok(result.Value) : BadRequest(result.Error);
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetOrder(Guid id, CancellationToken cancellationToken)
        {
            var result = await _sender.Send(new GetOrderByIdQuery(id), cancellationToken);
            if (result.IsFailure)
                return NotFound(result.Error);

            if (!User.IsAdmin() && result.Value.UserId != User.GetRequiredUserId())
                return Forbid();

            return Ok(result.Value);
        }

        /// <summary>User submits a refund request — no Stripe call, sets status to RefundRequested.</summary>
        [HttpPost("{id:guid}/refund-request")]
        [EnableRateLimiting("write")]
        public async Task<IActionResult> RequestRefund(
            Guid id,
            [FromBody] RefundRequestBody request,
            CancellationToken cancellationToken)
        {
            var result = await _sender.Send(
                new RequestRefundCommand(id, User.GetRequiredUserId(), request.Reason),
                cancellationToken);

            if (result.IsFailure)
            {
                return result.Error.Code switch
                {
                    "Order.NotFound" => NotFound(result.Error),
                    "Order.Forbidden" => Forbid(),
                    _ => BadRequest(result.Error)
                };
            }

            return Ok(new { message = "Refund request submitted. An admin will review it shortly." });
        }

        /// <summary>Admin approves a refund request — calls Stripe and finalises the refund.</summary>
        [HttpPost("{id:guid}/refund")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        [EnableRateLimiting("write")]
        public async Task<IActionResult> ApproveRefund(
            Guid id,
            [FromBody] RefundOrderRequest request,
            CancellationToken cancellationToken)
        {
            var result = await _sender.Send(
                new RefundOrderCommand(id, User.GetRequiredUserId(), User.IsAdmin(), request.Amount, request.Reason),
                cancellationToken);

            if (result.IsFailure)
            {
                return result.Error.Code switch
                {
                    "Order.NotFound" => NotFound(result.Error),
                    "Order.Forbidden" => Forbid(),
                    _ => BadRequest(result.Error)
                };
            }

            return Ok(new
            {
                orderId = result.Value.OrderId,
                refundId = result.Value.RefundId,
                status = result.Value.Status,
                message = result.Value.Message
            });
        }

        /// <summary>Admin rejects a refund request.</summary>
        [HttpPost("{id:guid}/refund/reject")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        [EnableRateLimiting("write")]
        public async Task<IActionResult> RejectRefund(
            Guid id,
            [FromBody] RefundRequestBody request,
            CancellationToken cancellationToken)
        {
            var result = await _sender.Send(
                new RejectRefundCommand(id, User.GetRequiredUserId(), request.Reason),
                cancellationToken);

            if (result.IsFailure)
            {
                return result.Error.Code switch
                {
                    "Order.NotFound" => NotFound(result.Error),
                    _ => BadRequest(result.Error)
                };
            }

            return Ok(new { message = "Refund request rejected." });
        }
    }

    public sealed record RefundRequestBody(string? Reason);
}
