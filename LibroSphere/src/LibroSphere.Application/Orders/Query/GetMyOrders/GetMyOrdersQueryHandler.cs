using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Domain.Entities.Orders;

namespace LibroSphere.Application.Orders.Query.GetMyOrders
{
    internal sealed class GetMyOrdersQueryHandler : IQueryHandler<GetMyOrdersQuery, PagedResponse<Order>>
    {
        private readonly IOrderService _orderService;

        public GetMyOrdersQueryHandler(IOrderService orderService)
        {
            _orderService = orderService;
        }

        public async Task<Result<PagedResponse<Order>>> Handle(GetMyOrdersQuery request, CancellationToken cancellationToken)
        {
            var orders = await _orderService.GetOrdersForUserAsync(request.BuyerEmail);
            var filteredOrders = orders
                .Where(order => !request.Status.HasValue || order.Status == request.Status.Value)
                .ToList();

            return Result.Success(PagedResponse<Order>.Create(filteredOrders, request.Page, request.PageSize));
        }
    }
}
