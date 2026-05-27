using LibroSphere.Application.Orders.Command.CreateOrder;
using LibroSphere.Application.Orders.Query.GetAllOrders;
using LibroSphere.Application.Orders.Query.GetMyOrders;
using LibroSphere.Application.Orders.Query.GetOrderById;
using LibroSphere.Application.Abstractions.Identity;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Application.Abstractions;
using LibroSphere.WebApi.Extensions;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
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
        private readonly IPaymentService _paymentService;
        private readonly IOrderService _orderService;
        private readonly IUserBookRepository _userBookRepository;

        public OrdersController(
            ISender sender,
            IPaymentService paymentService,
            IOrderService orderService,
            IUserBookRepository userBookRepository)
        {
            _sender = sender;
            _paymentService = paymentService;
            _orderService = orderService;
            _userBookRepository = userBookRepository;
        }

        [HttpPost]
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
            var result = await _sender.Send(new GetAllOrdersQuery(searchTerm, status, page, pageSize), cancellationToken);
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

            if (!User.IsAdmin() && result.Value.UserId != User.GetRequiredUserId())
            {
                return Forbid();
            }

            return Ok(result.Value);
        }

        [HttpPost("{id:guid}/refund")]
        [Authorize(Roles = ApplicationRoles.Admin)]
        public async Task<IActionResult> RefundOrder(
            Guid id,
            [FromBody] RefundOrderRequest request,
            CancellationToken cancellationToken)
        {
            var order = await _orderService.GetOrderByIdAsync(id);
            if (order is null)
            {
                return NotFound(new { code = "Order.NotFound", message = "Order was not found." });
            }

            if (!User.IsAdmin() && order.UserId != User.GetRequiredUserId())
            {
                return Forbid();
            }

            if (order.Status == OrderStatus.Refunded || order.Status == OrderStatus.PartiallyRefunded)
            {
                return BadRequest(new
                {
                    code = "Order.Refund.AlreadyRefunded",
                    message = "This order has already been refunded."
                });
            }

            if (order.Status != OrderStatus.PaymentReceived)
            {
                return BadRequest(new
                {
                    code = "Order.Refund.InvalidStatus",
                    message = "Only paid orders can be refunded."
                });
            }

            if (request.Amount.HasValue && request.Amount.Value > order.TotalAmount.amount)
            {
                return BadRequest(new
                {
                    code = "Order.Refund.ExceedsTotal",
                    message = "Refund amount cannot exceed the order total."
                });
            }

            var isFullRefund = request.Amount is null || request.Amount.Value >= order.TotalAmount.amount;

            long? amountInCents = null;
            if (!isFullRefund)
            {
                amountInCents = (long)Math.Round(request.Amount!.Value * 100m);
            }

            var refundResult = await _paymentService.RefundPaymentIntentAsync(
                order.PaymentIntentId,
                amountInCents,
                request.Reason,
                cancellationToken);

            if (refundResult.IsFailure)
            {
                return BadRequest(refundResult.Error);
            }

            order.UpdateStatus(isFullRefund ? OrderStatus.Refunded : OrderStatus.PartiallyRefunded);

            if (isFullRefund)
            {
                var userLibrary = await _userBookRepository.GetByUserIdAsync(order.UserId, cancellationToken);
                foreach (var item in order.Items)
                {
                    var userBook = userLibrary.FirstOrDefault(ub => ub.BookId == item.BookId);
                    if (userBook != null)
                    {
                        await _userBookRepository.RemoveAsync(userBook);
                    }
                }
            }

            await _orderService.SaveChangesAsync(cancellationToken);

            return Ok(new
            {
                orderId = order.Id,
                refundId = refundResult.Value,
                status = order.Status.ToString(),
                message = isFullRefund
                    ? "Refund successful. Books have been removed from user's library."
                    : "Partial refund successful."
            });
        }
    }
}
