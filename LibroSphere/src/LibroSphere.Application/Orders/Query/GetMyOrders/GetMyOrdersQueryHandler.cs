using LibroSphere.Application.Abstractions;
using LibroSphere.Application.Abstractions.Messaging;
using LibroSphere.Application.Common.Models;
using LibroSphere.Application.Orders.Query.GetAllOrders;

namespace LibroSphere.Application.Orders.Query.GetMyOrders
{
    internal sealed class GetMyOrdersQueryHandler : IQueryHandler<GetMyOrdersQuery, PagedResponse<OrderListItemResponse>>
    {
        private readonly IOrderService _orderService;

        public GetMyOrdersQueryHandler(IOrderService orderService)
        {
            _orderService = orderService;
        }

        public async Task<Result<PagedResponse<OrderListItemResponse>>> Handle(GetMyOrdersQuery request, CancellationToken cancellationToken)
        {
            var page = Math.Max(1, request.Page);
            var pageSize = Math.Clamp(request.PageSize, 1, 100);

            var orders = await _orderService.GetOrdersForUserAsync(request.UserId);
            var dtos = orders
                .Where(order => !request.Status.HasValue || order.Status == request.Status.Value)
                .OrderByDescending(order => order.OrderDate)
                .Select(OrderListItemResponse.FromOrder)
                .ToList();

            return Result.Success(PagedResponse<OrderListItemResponse>.Create(dtos, page, pageSize));
        }
    }
}
