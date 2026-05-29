using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Command.RequestRefund
{
    internal sealed class RequestRefundCommandHandler : ICommandHandler<RequestRefundCommand>
    {
        private readonly IOrderService _orderService;

        public RequestRefundCommandHandler(IOrderService orderService)
        {
            _orderService = orderService;
        }

        public async Task<Result> Handle(RequestRefundCommand request, CancellationToken cancellationToken)
        {
            var order = await _orderService.GetOrderByIdAsync(request.OrderId);
            if (order is null)
                return Result.Failure(new Error("Order.NotFound", "Order was not found."));

            if (order.UserId != request.RequestingUserId)
                return Result.Failure(new Error("Order.Forbidden", "You can only request a refund for your own orders."));

            if (order.Status != OrderStatus.PaymentReceived && order.Status != OrderStatus.RefundRejected)
                return Result.Failure(new Error(
                    "Order.Refund.InvalidStatus",
                    "Refund can only be requested for paid orders or previously rejected refund requests."));

            order.UpdateStatus(OrderStatus.RefundRequested);
            await _orderService.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
