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

            if (!User.IsAdmin() && !string.Equals(result.Value.BuyerEmail, User.GetRequiredEmail(), StringComparison.OrdinalIgnoreCase))
            {
                return Forbid();
            }

            return Ok(result.Value);
        }

        [HttpPost("{id:guid}/refund")]
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

            if (!User.IsAdmin() && !string.Equals(order.BuyerEmail, User.GetRequiredEmail(), StringComparison.OrdinalIgnoreCase))
            {
                return Forbid();
            }

            if (order.Status != OrderStatus.PaymentReceived)
            {
                return BadRequest(new
                {
                    code = "Order.Refund.InvalidStatus",
                    message = "Only paid orders can be refunded."
                });
            }

            long? amountInCents = null;
            if (request.Amount is > 0)
            {
                amountInCents = (long)Math.Round(request.Amount.Value * 100m);
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

            order.UpdateStatus(OrderStatus.Refunded);

            // Remove books from user's library when order is refunded
            var userLibrary = await _userBookRepository.GetByEmailAsync(order.BuyerEmail, cancellationToken);
            foreach (var item in order.Items)
            {
                var userBook = userLibrary.FirstOrDefault(ub => ub.BookId == item.BookId);
                if (userBook != null)
                {
                    await _userBookRepository.RemoveAsync(userBook);
                }
            }

            await _orderService.SaveChangesAsync(cancellationToken);

            return Ok(new
            {
                orderId = order.Id,
                refundId = refundResult.Value,
                status = order.Status.ToString(),
                message = "Refund successful. Books have been removed from user's library."
            });
        }
    }
}
