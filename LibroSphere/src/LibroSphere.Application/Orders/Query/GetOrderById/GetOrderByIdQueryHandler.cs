using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Domain.Abstraction;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Query.GetOrderById
{
    internal sealed class GetOrderByIdQueryHandler : IQueryHandler<GetOrderByIdQuery, Order>
    {
        private readonly IOrderService _orderService;

        public GetOrderByIdQueryHandler(IOrderService orderService)
        {
            _orderService = orderService;
        }

        public async Task<Result<Order>> Handle(GetOrderByIdQuery request, CancellationToken cancellationToken)
        {
            var order = await _orderService.GetOrderByIdAsync(request.OrderId);
            return order is not null
                ? Result.Success(order)
                : Result.Failure<Order>(Error.NullValue);
        }
    }
}
