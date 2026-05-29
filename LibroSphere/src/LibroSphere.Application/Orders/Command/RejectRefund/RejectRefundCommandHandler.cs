using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Command.RejectRefund
{
    internal sealed class RejectRefundCommandHandler : ICommandHandler<RejectRefundCommand>
    {
        private readonly IOrderService _orderService;

        public RejectRefundCommandHandler(IOrderService orderService)
        {
            _orderService = orderService;
        }

        public async Task<Result> Handle(RejectRefundCommand request, CancellationToken cancellationToken)
        {
            var order = await _orderService.GetOrderByIdAsync(request.OrderId);
            if (order is null)
                return Result.Failure(new Error("Order.NotFound", "Order was not found."));

            if (order.Status != OrderStatus.RefundRequested)
                return Result.Failure(new Error(
                    "Order.Refund.InvalidStatus",
                    "Only orders with a pending refund request can be rejected."));

            order.UpdateStatus(OrderStatus.RefundRejected);
            await _orderService.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
