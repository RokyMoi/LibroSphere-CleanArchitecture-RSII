using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Command.CreateOrder
{
    internal sealed class CreateOrderCommandHandler : ICommandHandler<CreateOrderCommand, Order>
    {
        private readonly IOrderService _orderService;

        public CreateOrderCommandHandler(IOrderService orderService)
        {
            _orderService = orderService;
        }

        public async Task<Result<Order>> Handle(CreateOrderCommand request, CancellationToken cancellationToken)
        {
            return await _orderService.CreateOrderAsync(request.BuyerEmail, request.CartId);
        }
    }
}
