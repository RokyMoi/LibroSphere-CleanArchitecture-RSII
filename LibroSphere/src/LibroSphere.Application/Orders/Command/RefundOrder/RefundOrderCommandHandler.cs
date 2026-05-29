using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Abstractions.ShoppingServices;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.ManyToMany.IRepositories;
using LibroSphere.Domain.Entities.Orders;
using Microsoft.Extensions.Logging;

namespace LibroSphere.Application.Orders.Command.RefundOrder
{
    internal sealed class RefundOrderCommandHandler : ICommandHandler<RefundOrderCommand, RefundOrderResult>
    {
        private readonly IOrderService _orderService;
        private readonly IPaymentService _paymentService;
        private readonly IUserBookRepository _userBookRepository;
        private readonly ILogger<RefundOrderCommandHandler> _logger;

        public RefundOrderCommandHandler(
            IOrderService orderService,
            IPaymentService paymentService,
            IUserBookRepository userBookRepository,
            ILogger<RefundOrderCommandHandler> logger)
        {
            _orderService = orderService;
            _paymentService = paymentService;
            _userBookRepository = userBookRepository;
            _logger = logger;
        }

        public async Task<Result<RefundOrderResult>> Handle(RefundOrderCommand request, CancellationToken cancellationToken)
        {
            var order = await _orderService.GetOrderByIdAsync(request.OrderId);
            if (order is null)
                return Result.Failure<RefundOrderResult>(new Error("Order.NotFound", "Order was not found."));

            if (!request.IsAdmin && order.UserId != request.RequestingUserId)
                return Result.Failure<RefundOrderResult>(new Error("Order.Forbidden", "Access denied."));

            if (order.Status == OrderStatus.Refunded || order.Status == OrderStatus.PartiallyRefunded)
                return Result.Failure<RefundOrderResult>(new Error("Order.Refund.AlreadyRefunded", "This order has already been refunded."));

            if (order.Status != OrderStatus.PaymentReceived && order.Status != OrderStatus.RefundRequested)
                return Result.Failure<RefundOrderResult>(new Error("Order.Refund.InvalidStatus",
                    "Only orders in PaymentReceived or RefundRequested status can be approved for refund."));

            if (request.Amount.HasValue && request.Amount.Value > order.TotalAmount.amount)
                return Result.Failure<RefundOrderResult>(new Error("Order.Refund.ExceedsTotal", "Refund amount cannot exceed the order total."));

            var isFullRefund = request.Amount is null || request.Amount.Value >= order.TotalAmount.amount;
            long? amountInCents = isFullRefund ? null : (long)Math.Round(request.Amount!.Value * 100m);

            var refundResult = await _paymentService.RefundPaymentIntentAsync(
                order.PaymentIntentId, amountInCents, request.Reason, cancellationToken);

            if (refundResult.IsFailure)
                return Result.Failure<RefundOrderResult>(refundResult.Error);

            order.UpdateStatus(isFullRefund ? OrderStatus.Refunded : OrderStatus.PartiallyRefunded);

            if (isFullRefund)
            {
                var userLibrary = await _userBookRepository.GetByUserIdAsync(order.UserId, cancellationToken);
                var libraryByBookId = userLibrary.ToDictionary(ub => ub.BookId);
                var toRemove = order.Items
                    .Where(item => libraryByBookId.ContainsKey(item.BookId))
                    .Select(item => libraryByBookId[item.BookId])
                    .ToList();

                _userBookRepository.RemoveRange(toRemove);
            }

            await _orderService.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Order {OrderId} refunded by user {UserId}. Full={IsFullRefund}, RefundId={RefundId}",
                order.Id, request.RequestingUserId, isFullRefund, refundResult.Value);

            return Result.Success(new RefundOrderResult(
                order.Id,
                refundResult.Value,
                order.Status.ToString(),
                isFullRefund
                    ? "Refund successful. Books have been removed from user's library."
                    : "Partial refund successful."));
        }
    }
}
